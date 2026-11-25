# frozen_string_literal: true

require 'rails_helper'

# Regenerating an API token changes credentials, so it is never a GET: a link or image on another
# site must not be able to do it for a signed-in user.
RSpec.describe 'Regenerating an API token', type: :request do
  before { create(:org, abbreviation: 'guests') unless Org.guest.present? }

  let!(:user) do
    create(:user, :super_admin, api_token: 'current-token').tap do |admin|
      admin.perms << Perm.find_or_create_by(name: 'use_api')
    end
  end

  before { sign_in user }

  it 'has no GET route' do
    expect { get "/users/#{user.id}/refresh_token" }.to raise_error(ActionController::RoutingError)
    expect(user.reload.api_token).to eq('current-token')
  end

  it 'works from the profile page' do
    patch "/users/#{user.id}/refresh_token", xhr: true

    expect(response).to have_http_status(:ok)
    expect(user.reload.api_token).to be_present
    expect(user.api_token).not_to eq('current-token')
  end
end
