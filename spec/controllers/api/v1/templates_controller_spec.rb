# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Templates', type: :request do
  let(:api_client) { ApiClient.create!(name: 'Test Client', contact_email: 'test@example.com') }
  let(:access_token) do
    post '/api/v1/authenticate', params: {
      grant_type: 'client_credentials',
      client_id: api_client.client_id,
      client_secret: api_client.client_secret
    }.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    expect(response).to have_http_status(:ok)
    parsed_response = JSON.parse(response.body)
    parsed_response['access_token']
  end

  describe 'GET /api/v1/templates' do
    it 'returns a list of templates' do
      get '/api/v1/templates', headers: { 'Authorization' => "Bearer #{access_token}" }

      expect(response).to have_http_status(:ok)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_a(Hash)
      expect(parsed_response.keys).to include('items')
    end
  end
end
