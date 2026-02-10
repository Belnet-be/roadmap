# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Authentications', type: :request do
  describe 'GET /api/v1/heartbeat' do
    it 'returns a 200 OK status' do
      get '/api/v1/heartbeat'

      expect(response).to have_http_status(:ok)
    end

    it 'renders the heartbeat template' do
      get '/api/v1/heartbeat'
    end
  end
end
