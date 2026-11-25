# frozen_string_literal: true

require 'rails_helper'

# An API token (JWT) stops working as soon as the credentials it was issued for change or access is
# removed, not only at its expiry. Signing in to the API needs the exact email address, and the
# token's signature algorithm is fixed.
RSpec.describe 'API token lifecycle', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:org) { create(:org) }

  # Belnet sets a new user's org from the email domain and falls back to Org.guest
  before { create(:org, abbreviation: 'guests') unless Org.guest.present? }

  let!(:alice) { api_user('alice_smith@example.org') }
  let(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

  # A plan of Alice in the org, so that listing plans answers 200 for her and for the org's clients
  before { create(:plan, org: org).add_user!(alice.id, :creator) }

  def api_user(email)
    user = create(:user, email: email, api_token: SecureRandom.uuid)
    user.perms << Perm.find_or_create_by(name: 'use_api')
    user
  end

  # The access token, or nil when authentication fails
  def authenticate(credentials)
    post '/api/v1/authenticate', params: credentials.to_json, headers: json_headers
    response.status == 200 ? JSON.parse(response.body)['access_token'] : nil
  end

  def user_token(user, email: user.email, code: user.api_token)
    authenticate(grant_type: 'authorization_code', email: email, code: code)
  end

  def client_token(client)
    authenticate(grant_type: 'client_credentials', client_id: client.client_id,
                 client_secret: client.client_secret)
  end

  def api_status(token)
    get '/api/v1/plans', headers: json_headers.merge('Authorization' => "Bearer #{token}")
    response.status
  end

  def signed(payload, key: Rails.application.secret_key_base, algorithm: 'HS256')
    JWT.encode(payload.merge(exp: 1.hour.from_now.to_i), key, algorithm)
  end

  it 'works with the current credentials' do
    expect(api_status(user_token(alice))).to eq(200)
    expect(api_status(client_token(create(:api_client, org: org)))).to eq(200)
  end

  context 'with a user token' do
    it 'stops working when the user regenerates the API token' do
      token = user_token(alice)
      alice.generate_token!

      expect(api_status(token)).to eq(401)
      expect(api_status(user_token(alice.reload))).to eq(200)
    end

    it 'stops working when API access is removed' do
      token = user_token(alice)
      alice.perms.delete(Perm.find_by(name: 'use_api'))

      expect(api_status(token)).to eq(401)
    end

    it 'stops working when the account is deactivated' do
      token = user_token(alice)
      alice.update!(active: false)

      expect(api_status(token)).to eq(401)
    end
  end

  context 'with an API client token' do
    let!(:client) { create(:api_client, org: org) }

    it 'stops working when the credentials are refreshed' do
      token = client_token(client)
      client.generate_credentials
      client.save!

      expect(api_status(token)).to eq(401)
      expect(api_status(client_token(client.reload))).to eq(200)
    end

    it 'stops working when only the secret changes' do
      token = client_token(client)
      client.update!(client_secret: SecureRandom.uuid)

      expect(api_status(token)).to eq(401)
    end
  end

  it 'refuses tokens without the credentials fingerprint, with another algorithm or unsigned' do
    cv = Api::V1::Auth::Jwt::JsonWebToken.credentials_fingerprint(alice)

    expect(api_status(signed({ client_id: alice.email }))).to eq(401)
    expect(api_status(signed({ client_id: alice.email, cv: cv }, algorithm: 'HS512'))).to eq(401)
    expect(api_status(signed({ client_id: alice.email, cv: cv }, key: nil, algorithm: 'none'))).to eq(401)
    expect(api_status(signed({ client_id: alice.email, cv: cv }))).to eq(200)
  end

  it 'refuses expired tokens' do
    token = user_token(alice)

    travel(25.hours) { expect(api_status(token)).to eq(401) }
  end

  describe 'signing in to the API' do
    it 'needs the exact email address, in any case' do
      expect(user_token(alice, email: 'ALICE_SMITH@example.org')).to be_present
      expect(user_token(alice, email: '%')).to be_nil
      expect(user_token(alice, email: 'alice%')).to be_nil
      expect(user_token(alice, email: 'aliceXsmith@example.org')).to be_nil
    end

    it 'refuses a wrong secret and secrets that are not text' do
      expect(user_token(alice, code: 'wrong')).to be_nil
      expect(user_token(alice, code: [alice.api_token])).to be_nil
      expect(authenticate(grant_type: 'client_credentials', client_id: { 'a' => 1 }, client_secret: 'x')).to be_nil
    end
  end
end
