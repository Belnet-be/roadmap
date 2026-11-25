# frozen_string_literal: true

require 'rails_helper'

# Who owns a plan created through POST /api/v1/plans. A user always creates plans for
# themselves. An API client may create a plan for an existing user of its own organisation,
# named as the contact. The DMP contact is only contributor data: it never picks an account by
# ORCID iD or email, never invites anyone and never changes an existing user.
RSpec.describe 'Plan ownership through the API', type: :request do
  let!(:org_a) { create(:org) }
  let!(:org_b) { create(:org) }
  let!(:template) { create(:template, :publicly_visible, published: true, is_default: true) }
  let!(:orcid) do
    IdentifierScheme.find_by(name: 'orcid') ||
      create(:identifier_scheme, name: 'orcid', identifier_prefix: 'https://orcid.org/',
                                 context_count: 0, for_authentication: true, for_users: true,
                                 for_contributors: true)
  end

  # Belnet sets a new user's org from the email domain and falls back to Org.guest
  before do
    create(:org, abbreviation: 'guests') unless Org.guest.present?
    Ugent::OrgDomain.create!(name: 'institute-a.example', org: org_a)
    Ugent::OrgDomain.create!(name: 'institute-b.example', org: org_b)
  end

  let!(:alice) { api_user('alice@institute-a.example') }
  let!(:ben) { create(:user, email: 'ben@institute-b.example') }
  let!(:ben_orcid) do
    Identifier.create!(identifier_scheme: orcid, value: '0000-0002-1825-0097', identifiable: ben,
                       attrs: { 'provider' => 'orcid', 'uid' => '0000-0002-1825-0097' })
  end

  let(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

  def api_user(email)
    user = create(:user, email: email, api_token: SecureRandom.uuid)
    user.perms << Perm.find_or_create_by(name: 'use_api')
    user
  end

  def token(credentials)
    post '/api/v1/authenticate', params: credentials.to_json, headers: json_headers
    JSON.parse(response.body)['access_token']
  end

  def user_token(user)
    token(grant_type: 'authorization_code', email: user.email, code: user.api_token)
  end

  def client_token(client)
    token(grant_type: 'client_credentials', client_id: client.client_id, client_secret: client.client_secret)
  end

  def create_plan(token:, contact:)
    dmp = { title: 'API ownership test', contact: contact,
            extension: [{ dmproadmap: { template: { id: template.id } } }] }
    post '/api/v1/plans', params: { total_items: 1, items: [{ dmp: dmp }] }.to_json,
                          headers: json_headers.merge('Authorization' => "Bearer #{token}")
  end

  def created_plan
    Plan.order(:id).last
  end

  def creators(plan)
    plan.roles.select(&:creator?).map(&:user)
  end

  def everything_counted
    [Plan.count, User.count, ActionMailer::Base.deliveries.size]
  end

  context 'when a user creates a plan' do
    it 'makes the caller the owner, even when the contact is another existing user' do
      create_plan(token: user_token(alice), contact: { name: 'Ben', mbox: ben.email })

      expect(response).to have_http_status(:created)
      expect(creators(created_plan)).to eq([alice])
      expect(created_plan.roles.map(&:user)).not_to include(ben)
    end

    it "doesn't use an ORCID iD in the contact to pick an account" do
      create_plan(token: user_token(alice),
                  contact: { name: 'Someone', mbox: 'someone@example.org',
                             contact_id: { type: 'orcid', identifier: ben_orcid.value } })

      expect(response).to have_http_status(:created)
      expect(creators(created_plan)).to eq([alice])
      expect(created_plan.roles.map(&:user)).not_to include(ben)
    end

    it 'can read back the plan it created' do
      access_token = user_token(alice)
      create_plan(token: access_token,
                  contact: { name: 'Someone', mbox: 'someone@example.org',
                             contact_id: { type: 'orcid', identifier: ben_orcid.value } })
      get "/api/v1/plans/#{created_plan.id}",
          headers: json_headers.merge('Authorization' => "Bearer #{access_token}")

      expect(response).to have_http_status(:ok)
    end

    it "doesn't change the identity of an existing user named as contact" do
      access_token = user_token(alice)

      # With an affiliation: the old code then invited the contact and
      # copied the submitted ORCID iD onto the existing account
      expect do
        create_plan(token: access_token,
                    contact: { name: 'Ben', mbox: ben.email, affiliation: { name: org_b.name },
                               contact_id: { type: 'orcid', identifier: '0000-0000-0000-0001' } })
      end.not_to(change { ben.reload.identifiers.map(&:value).sort })
    end

    it "doesn't create or invite an account for an unknown contact" do
      access_token = user_token(alice)
      users_before = User.count
      mails_before = ActionMailer::Base.deliveries.size

      expect { create_plan(token: access_token, contact: { name: 'New person', mbox: 'new.person@example.org' }) }
        .to change(Plan, :count).by(1)
      expect(User.count).to eq(users_before)
      expect(ActionMailer::Base.deliveries.size).to eq(mails_before)
      expect(creators(created_plan)).to eq([alice])
    end
  end

  context 'when an API client creates a plan' do
    let!(:carol) { create(:user, email: 'carol@institute-a.example') }
    let(:client) { create(:api_client, org: org_a) }

    it 'makes the contact the owner when they are an existing user of its organisation' do
      create_plan(token: client_token(client), contact: { name: 'Carol', mbox: carol.email })

      expect(response).to have_http_status(:created)
      expect(creators(created_plan)).to eq([carol])
      expect(created_plan.api_client_id).to eq(client.id)
    end

    it 'refuses a contact from another organisation' do
      access_token = client_token(client)

      expect { create_plan(token: access_token, contact: { name: 'Ben', mbox: ben.email }) }
        .not_to(change { everything_counted })
      expect(response).to have_http_status(:bad_request)
    end

    it 'refuses an unknown contact instead of inviting them' do
      access_token = client_token(client)

      expect { create_plan(token: access_token, contact: { name: 'New', mbox: 'new@institute-a.example' }) }
        .not_to(change { everything_counted })
      expect(response).to have_http_status(:bad_request)
    end

    it 'refuses when the API client has no organisation' do
      access_token = client_token(create(:api_client, org: nil))

      expect { create_plan(token: access_token, contact: { name: 'Carol', mbox: carol.email }) }
        .not_to(change { everything_counted })
      expect(response).to have_http_status(:bad_request)
    end

    it 'never gives the plan to the user whose ID happens to equal the API client ID' do
      same_id_client = create(:api_client, id: ben.id, org: org_a)

      create_plan(token: client_token(same_id_client), contact: { name: 'Nobody', mbox: 'nobody@example.org' })

      expect(Role.where(user_id: ben.id)).to be_empty
    end
  end
end
