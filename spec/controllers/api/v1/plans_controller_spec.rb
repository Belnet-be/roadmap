# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Plans', type: :request do
  let!(:org) { Org.create!(name: 'Test Org') }

  let!(:api_client) { ApiClient.create!(name: 'Test Client', contact_email: 'test@example.com', org: org) }
  let!(:access_token) do
    post '/api/v1/authenticate', params: {
      grant_type: 'client_credentials',
      client_id: api_client.client_id,
      client_secret: api_client.client_secret
    }.to_json, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    expect(response).to have_http_status(:ok)
    parsed_response = JSON.parse(response.body)
    parsed_response['access_token']
  end

  # Plan is dependent on Org and Template, so we need to create those first
  let!(:funder_org) { Org.create!(name: 'Funder Org') }
  let!(:template) do
    Template.create!(title: 'Test Template', org: org, locale: 'en', version: 0,
                     published: 1, archived: 0)
  end
  let!(:plan) do
    Plan.create!(title: 'Test Plan', description: 'A test plan', template: template, org: org,
                 visibility: 1, complete: 0, funder: funder_org, funding_status: 0)
  end

  describe 'GET /api/v1/plans' do
    it 'returns a list of plans' do
      get '/api/v1/plans', headers: { 'Authorization' => "Bearer #{access_token}" }

      expect(response).to have_http_status(:ok)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_a(Hash)
      expect(parsed_response.keys).to include('items')
    end

    it 'gets a plan by id' do
      get "/api/v1/plans/#{plan.id}", headers: { 'Authorization' => "Bearer #{access_token}" }

      expect(response).to have_http_status(:ok)
    end

    # create plan endpoint
    it 'creates a new plan' do
      plan_params = {
        total_items: 1,
        items: [
          {
            dmp: {
              title: 'Examination of some interesting topics in biochemistry',
              contact: {
                name: 'Jane Doe',
                mbox: 'jane.doe@example.edu',
                affiliation: { name: 'Example University' },
                contact_id: { type: 'orcid', identifier: '0000-0000-0000-0000' }
              },
              contributor: [
                {
                  name: 'John Smith',
                  mbox: 'john.smith@un.edu',
                  role: [
                    'https://dictionary.casrai.org/Contributor_Roles/Data_curation',
                    'https://dictionary.casrai.org/Contributor_Roles/Investigation'
                  ],
                  affiliation: {
                    name: 'University of Nowhere',
                    affiliation_id: { type: 'ror', identifier: 'https://ror.org/123abc45y' }
                  },
                  contributor_id: { type: 'orcid', identifier: 'https://orcid.org/0000-0000-0000-0000' }
                }
              ],
              extension: [
                {
                  dmproadmap: {
                    template: { id: template.id }
                  }
                }
              ]
            }
          }
        ]
      }

      headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{access_token}"
      }

      post '/api/v1/plans', params: plan_params.to_json, headers: headers

      puts "Response: #{response.inspect}"
      expect(response).to have_http_status(:created)

      parsed_response = JSON.parse(response.body)
      expect(parsed_response['items'].first['dmp']['title']).to eq('Examination of some interesting topics in biochemistry')
    end
  end
end
