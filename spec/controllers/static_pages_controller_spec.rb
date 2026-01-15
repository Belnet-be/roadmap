# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do
  # Add other tests later

  describe 'GET #version' do
    it 'returns a successful response and assigns version variables' do
      get :version
      expect(response).to be_successful
    end
  end
end
