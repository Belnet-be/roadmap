# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do
  # Add other tests later

  describe 'GET #version' do
    it 'returns a successful response and assigns version variables' do
      get :version
      expect(response).to be_successful
      expect(assigns(:ruby_version)).to eq(RUBY_VERSION)
      expect(assigns(:rails_version)).to eq(Rails.version)
      expect(assigns(:app_version)).not_to be_nil
      expect(assigns(:build_date)).not_to be_nil
      expect(assigns(:app_based_on)).to be_an(Hash)

      expect(assigns(:ruby_version)).to be_a(String)
      expect(assigns(:rails_version)).to be_a(String)
      expect(assigns(:app_version)).to be_a(String)
      expect(assigns(:build_date)).to be_a(String)

      # JS Dependencies
      expect(assigns(:js_dependencies)).to be_an(Array)
      expect(assigns(:js_dependencies)).not_to be_empty

      # Gems
      expect(assigns(:gems)).to be_an(Array)
      expect(assigns(:gems)).not_to be_empty
    end
  end
end
