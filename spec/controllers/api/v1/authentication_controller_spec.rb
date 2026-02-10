# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Authentications', type: :request do
  let(:api_client) { ApiClient.create!(name: 'Test Client', contact_email: 'test@example.com') }

  describe 'POST /api/v1/authenticate' do
    it 'authenticates with valid client credentials' do
      puts api_client.inspect
      post '/api/v1/authenticate', params: {
        grant_type: 'client_credentials',
        client_id: api_client.client_id,
        client_secret: api_client.client_secret
      }.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

      expect(response).to have_http_status(:ok)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_a(Hash)
      expect(parsed_response.keys).to include('token_type', 'access_token', 'expires_in')
    end
  end
end
