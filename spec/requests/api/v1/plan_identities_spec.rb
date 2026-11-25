# frozen_string_literal: true

require 'rails_helper'

# The data in a DMP sent to POST /api/v1/plans only describes the new plan. It never reuses,
# moves or changes the identifiers, contributors, organisations or grants of other records, and
# it never changes an existing plan named in the DMP.
RSpec.describe 'Identities in plans created through the API', type: :request do
  let!(:org_a) { create(:org) }
  let!(:template) { create(:template, :publicly_visible, published: true, is_default: true) }
  let!(:orcid) { scheme('orcid', 'https://orcid.org/', for_contributors: true, for_users: true) }
  let!(:ror) { scheme('ror', 'https://ror.org/', for_orgs: true) }
  let!(:url) { scheme('url', '', for_plans: true) }

  # Belnet sets a new user's org from the email domain and falls back to Org.guest. Orgs found
  # through the API get the default language.
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

  # Someone else's private plan, with a contact that has an ORCID iD
  let!(:other_plan) { create(:plan, :creator, template: template) }
  let!(:other_contact) do
    create(:contributor, plan: other_plan, name: 'Other Person', email: 'other.person@example.org',
                         roles_count: 0, data_curation: true)
  end
  let!(:other_orcid) do
    Identifier.create!(identifier_scheme: orcid, value: '0000-0002-1825-0097', identifiable: other_contact)
  end

  let(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

  def scheme(name, prefix, **flags)
    IdentifierScheme.find_by(name: name) ||
      create(:identifier_scheme, name: name, identifier_prefix: prefix, context_count: 0, **flags)
  end

  def access_token
    @access_token ||= begin
      post '/api/v1/authenticate',
           params: { grant_type: 'authorization_code', email: alice.email, code: alice.api_token }.to_json,
           headers: json_headers
      JSON.parse(response.body)['access_token']
    end
  end

  def create_plan(contact:, **dmp)
    token = access_token
    dmp = { title: 'API identity test', contact: contact,
            extension: [{ dmproadmap: { template: { id: template.id } } }] }.merge(dmp)
    post '/api/v1/plans', params: { total_items: 1, items: [{ dmp: dmp }] }.to_json,
                          headers: json_headers.merge('Authorization' => "Bearer #{token}")
  end

  def new_plan
    Plan.where.not(id: other_plan.id).order(:id).last
  end

  def stored_contact
    new_plan.contributors.find(&:data_curation?)
  end

  it "stores the contact's own ORCID iD and leaves other contributors' iDs alone" do
    create_plan(contact: { name: 'Probe Contact', mbox: 'probe.contact@example.org',
                           contact_id: { type: 'orcid', identifier: 'https://orcid.org/0000-0000-0000-0001' } })

    expect(response).to have_http_status(:created)
    expect(stored_contact.identifiers.map(&:value)).to eq(['https://orcid.org/0000-0000-0000-0001'])
    expect(other_orcid.reload.identifiable).to eq(other_contact)
  end

  it 'gives the contact its own record when the ORCID iD is already known' do
    create_plan(contact: { name: 'Probe Contact', mbox: 'probe.contact@example.org',
                           contact_id: { type: 'orcid', identifier: other_orcid.value } })

    expect(response).to have_http_status(:created)
    expect(stored_contact.name).to eq('Probe Contact')
    expect(stored_contact.identifiers.map(&:value)).to eq([other_orcid.value])
    expect(stored_contact.identifiers.map(&:id)).not_to include(other_orcid.id)
    expect(other_orcid.reload.identifiable).to eq(other_contact)
  end

  # The response shows the plan owner (the caller) as "contact" and the submitted contact among
  # the contributors; that is the existing presenter design.
  it "uses the submitted details, not another plan's copy, when the email is already known" do
    create_plan(contact: { name: 'Probe Name', mbox: other_contact.email })

    expect(response).to have_http_status(:created)
    expect(stored_contact&.name).to eq('Probe Name')
    expect(response.body).to include('Probe Name')
    expect(response.body).not_to include(other_contact.name, other_contact.phone)
    expect(other_contact.reload.plan).to eq(other_plan)
  end

  it "doesn't add or move organisation identifiers" do
    plain_org = create(:org, name: 'Plain University')
    ror_org = create(:org, name: 'ROR University')
    ror_id = Identifier.create!(identifier_scheme: ror, value: 'https://ror.org/000000001', identifiable: ror_org)

    create_plan(contact: { name: 'Probe Contact', mbox: 'probe.contact@example.org',
                           affiliation: { name: 'Plain University',
                                          affiliation_id: { type: 'ror', identifier: 'https://ror.org/00abcde12' } } })

    expect(plain_org.reload.identifiers).to be_empty
    expect(ror_id.reload.identifiable).to eq(ror_org)
  end

  it "stores the submitted grant number, not another plan's" do
    funder = create(:org, name: 'Some Funder')
    other_grant = Identifier.create!(identifier_scheme: url, value: 'https://cordis.europa.eu/project/id/999999',
                                     identifiable: other_plan)
    other_plan.update_column(:grant_id, other_grant.id)

    grant_id = { type: 'url', identifier: 'https://cordis.europa.eu/project/id/101' }
    create_plan(contact: { name: 'Probe Contact', mbox: 'probe.contact@example.org' },
                project: [{ title: 'Project', funding: [{ name: funder.name, grant_id: grant_id }] }])

    expect(response).to have_http_status(:created)
    expect(new_plan.grant&.value).to eq('https://cordis.europa.eu/project/id/101')
    expect(other_plan.reload.grant&.value).to eq('https://cordis.europa.eu/project/id/999999')
  end

  it "doesn't change an existing plan named in dmp_id" do
    expect do
      create_plan(contact: { name: 'Injected', mbox: 'injected@example.org' },
                  dmp_id: { type: 'url', identifier: "https://dmponline.be/plans/#{other_plan.id}" })
    end.not_to(change { other_plan.reload.contributors.map(&:email).sort })
    expect(response).to have_http_status(:bad_request)
  end
end
