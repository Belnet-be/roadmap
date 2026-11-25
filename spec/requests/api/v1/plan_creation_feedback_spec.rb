# frozen_string_literal: true

require 'rails_helper'
require 'json_schemer'

# Functional feedback from UAT (September and November 2026) on POST /api/v1/plans and the
# Belnet plan list: a DMP is refused with a clear 400 instead of being stored differently from
# what was sent.
RSpec.describe 'Creating plans through the API: feedback from UAT', type: :request do
  let!(:org_a) { create(:org, managed: true, name: 'Institute A') }
  let!(:org_b) { create(:org, managed: true, name: 'Institute B') }
  let!(:default_template) { create(:template, :publicly_visible, published: true, is_default: true) }
  let!(:public_template) { create(:template, :publicly_visible, published: true, org: org_b) }
  let!(:own_template) { create(:template, :organisationally_visible, published: true, org: org_a) }
  let!(:other_org_template) { create(:template, :organisationally_visible, published: true, org: org_b) }
  let!(:unpublished_template) { create(:template, :organisationally_visible, published: false, org: org_a) }

  # Belnet sets a new user's org from the email domain and falls back to Org.guest
  before do
    create(:org, abbreviation: 'guests') unless Org.guest.present?
    create(:language, default_language: true) unless Language.default.present?
    Ugent::OrgDomain.create!(name: 'institute-a.example', org: org_a)
  end

  let!(:alice) do
    create(:user, email: 'alice@institute-a.example', api_token: SecureRandom.uuid).tap do |user|
      user.perms << Perm.find_or_create_by(name: 'use_api')
    end
  end

  let(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

  def token
    @token ||= begin
      post '/api/v1/authenticate',
           params: { grant_type: 'authorization_code', email: alice.email, code: alice.api_token }.to_json,
           headers: json_headers
      JSON.parse(response.body)['access_token']
    end
  end

  def create_plan(title: 'API feedback test', template_id: :none, **dmp)
    dmp = { title: title, contact: { name: 'Alice', mbox: alice.email } }.merge(dmp)
    dmp[:extension] = [{ dmproadmap: { template: { id: template_id } } }] unless template_id == :none
    post '/api/v1/plans', params: { total_items: 1, items: [{ dmp: dmp }] }.to_json,
                          headers: json_headers.merge('Authorization' => "Bearer #{token}")
  end

  def errors
    JSON.parse(response.body)['errors'].flatten.join(' ')
  end

  def returned_dmp
    JSON.parse(response.body)['items'].first['dmp']
  end

  describe 'the template' do
    it 'refuses a template id that does not exist, instead of using the default template' do
      expect { create_plan(template_id: 99_999_999) }.not_to change(Plan, :count)
      expect(response).to have_http_status(:bad_request)
      expect(errors).to include('template')
    end

    it 'refuses templates the caller may not use' do
      [other_org_template, unpublished_template].each do |template|
        expect { create_plan(template_id: template.id) }.not_to change(Plan, :count)
        expect(response).to have_http_status(:bad_request), "template #{template.id} was accepted"
      end
    end

    it 'uses the public template or the template of its own organisation that it names' do
      [public_template, own_template].each do |template|
        create_plan(title: "Plan on template #{template.id}", template_id: template.id)
        expect(response).to have_http_status(:created)
        expect(Plan.find_by(title: "Plan on template #{template.id}").template).to eq(template)
      end
    end

    it 'still uses the default template when the DMP names none' do
      create_plan(title: 'Plan without a template')

      expect(response).to have_http_status(:created)
      expect(Plan.find_by(title: 'Plan without a template').template).to eq(default_template)
    end
  end

  describe 'the funding status' do
    def create_funded_plan(status)
      grant_id = { type: 'url', identifier: 'https://cordis.europa.eu/project/id/101' }
      funding = { name: 'Some Funder', funding_status: status, grant_id: grant_id }
      create_plan(title: "Funding #{status}", project: [{ title: 'Project', funding: [funding] }])
    end

    before { create(:org, name: 'Some Funder', funder: true) }

    # The RDA value sent, the value stored and the RDA value returned ("applied" has no value of its own)
    {
      'granted' => %w[funded granted], 'rejected' => %w[denied rejected],
      'planned' => %w[planned planned], 'applied' => %w[planned planned]
    }.each do |sent, (stored, returned)|
      it "stores #{sent} as #{stored} and returns it" do
        create_funded_plan(sent)

        expect(response).to have_http_status(:created)
        expect(Plan.find_by(title: "Funding #{sent}").funding_status).to eq(stored)
        expect(returned_dmp['project'].first['funding'].first['funding_status']).to eq(returned)
      end
    end

    it 'refuses an unknown funding status' do
      expect { create_funded_plan('maybe') }.not_to change(Plan, :count)
      expect(response).to have_http_status(:bad_request)
      expect(errors).to include('funding_status')
    end
  end

  describe 'an affiliation on the contact' do
    it 'is accepted for a known organisation' do
      create(:org, name: 'Acme')
      create_plan(title: 'Known affiliation',
                  contact: { name: 'Alice', mbox: alice.email, affiliation: { name: 'Acme' } })

      expect(response).to have_http_status(:created)
    end

    # The affiliation exactly as the API returns it, sent back (a round trip)
    it 'is accepted as the API returns it, with abbreviation and ROR id' do
      ror = IdentifierScheme.find_by(name: 'ror') ||
            create(:identifier_scheme, name: 'ror', identifier_prefix: 'https://ror.org/', context_count: 0,
                                       for_orgs: true)
      acme = create(:org, name: 'Acme', abbreviation: 'ACME')
      Identifier.create!(identifier_scheme: ror, value: 'https://ror.org/000000001', identifiable: acme)
      affiliation = { name: 'Acme', abbreviation: 'ACME',
                      affiliation_id: { type: 'ror', identifier: 'https://ror.org/000000001' } }

      create_plan(title: 'Round trip affiliation',
                  contact: { name: 'Alice', mbox: alice.email, affiliation: affiliation })

      expect(response).to have_http_status(:created)
      expect(acme.reload.identifiers.count).to eq(1)
    end

    it 'is accepted for an unknown organisation' do
      create_plan(title: 'Unknown affiliation',
                  contact: { name: 'Alice', mbox: alice.email, affiliation: { name: 'Not In DMPonline' } })

      expect(response).to have_http_status(:created)
    end
  end

  # The schema the API refers to describes the affiliation it returns for contacts and contributors
  describe 'the published maDMP schema' do
    def schema_part(*path)
      schema = JSON.parse(File.read(Rails.root.join('public/files/openapi/maDMP-schema-1.0-belnet.json')))
      without_ids = lambda do |node|
        case node
        when Hash then node.except('$id').transform_values { |value| without_ids.call(value) }
        when Array then node.map { |value| without_ids.call(value) }
        else node
        end
      end
      JSONSchemer.schema(without_ids.call(schema.dig(*path)))
    end

    it 'describes the affiliation that the API returns' do
      create(:org, name: 'Acme')
      create_plan(title: 'Schema check', contact: { name: 'Alice', mbox: alice.email, affiliation: { name: 'Acme' } })

      contact = schema_part('properties', 'dmp', 'properties', 'contact', 'properties', 'affiliation')
      contributor = schema_part('properties', 'dmp', 'properties', 'contributor', 'items', 'properties', 'affiliation')
      expect(contact.valid?(returned_dmp['contact']['affiliation'])).to be(true)
      affiliations = returned_dmp['contributor'].filter_map { |item| item['affiliation'] }
      expect(affiliations).not_to be_empty
      expect(affiliations).to all(satisfy { |affiliation| contributor.valid?(affiliation) })
    end
  end

  # Validation times were shown in UTC in the plan screens
  describe 'validation times in the plan screens' do
    it 'are shown in Belgian time' do
      BelnetConfigValidationTopic.create!(org_id: nil, current_list_order: %w[ethics], full_list_order: %w[ethics])
      plan = create(:plan, template: default_template, org: org_a).tap { |live| live.add_user!(alice.id, :creator) }
      version = plan.create_plan_with_new_version!(reason: 'Version for the time zone test', current_user: alice,
                                                   original_plan: plan)
      validation = plan.governance_validations.create!(validated_plan: version, validation_topic: 'ethics',
                                                       requested_by: alice)
      validation.update_columns(created_at: Time.utc(2026, 9, 7, 9, 10, 13))
      sign_in alice

      get "/paginable/plans/#{plan.id}/validate/ALL"

      expect(response.body).to include('11:10')
      expect(response.body).not_to include('09:10')
    end
  end

  describe 'listing Belnet plans by time period' do
    it 'refuses a time period that is not one of the allowed values' do
      get '/api/belnet-v1/plans', params: { 'time-period' => '3M' },
                                  headers: json_headers.merge('Authorization' => "Bearer #{token}")

      expect(response).to have_http_status(:bad_request)
      expect(errors).to include('time-period')
    end
  end
end
