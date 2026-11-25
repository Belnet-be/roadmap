# frozen_string_literal: true

require 'rails_helper'

# Rate limits per address on logins, sign-ups, invitations, ORCID and Shibboleth logins and the API.
# Rack::Attack is off in the rest of the test suite; these examples switch it on.
RSpec.describe 'Rate limits', type: :request do
  around do |example|
    Rack::Attack.enabled = true
    Rack::Attack.reset!
    example.run
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.reset!
    @lowered&.each { |variable| ENV.delete(variable) }
  end

  let(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

  def from(address)
    { 'REMOTE_ADDR' => address }
  end

  # Sends a request; an error from the application itself doesn't matter here. No anonymous **
  # forwarding: release 5.0.x runs on Ruby 3.1.
  def attempt(verb, path, address, **options) # rubocop:disable Style/ArgumentsForwarding
    send(verb, path, env: from(address), **options) # rubocop:disable Style/ArgumentsForwarding
  rescue StandardError
    nil
  end

  # The limits are read from the environment on every request, as in production
  def lower_limit(name, to:)
    variable = "RACK_ATTACK_#{name}_LIMIT"
    (@lowered ||= []) << variable
    ENV[variable] = to.to_s
  end

  it 'limits API token requests per address, with a JSON answer' do
    10.times { attempt(:post, '/api/v1/authenticate', '198.51.100.10', params: '{}', headers: json_headers) }
    expect(response).not_to have_http_status(:too_many_requests)

    post '/api/v1/authenticate', params: '{}', headers: json_headers, env: from('198.51.100.10')
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers['Retry-After'].to_i).to be_between(1, 60)
    expect(JSON.parse(response.body)).to eq('errors' => ['Too many requests'])

    post '/api/v1/authenticate', params: '{}', headers: json_headers, env: from('198.51.100.11')
    expect(response).not_to have_http_status(:too_many_requests)
  end

  it 'limits all API calls per address' do
    lower_limit('API', to: 3)
    3.times { attempt(:get, '/api/v1/heartbeat', '198.51.100.20') }
    expect(response).to have_http_status(:ok)

    get '/api/v1/heartbeat', env: from('198.51.100.20')
    expect(response).to have_http_status(:too_many_requests)
  end

  it 'limits sign-in attempts per address' do
    credentials = { user: { email: 'nobody@example.org', password: 'wrong' } }
    4.times { attempt(:post, '/users/sign_in', '198.51.100.30', params: credentials) }
    expect(response).not_to have_http_status(:too_many_requests)

    post '/users/sign_in', params: credentials, env: from('198.51.100.30')
    expect(response).to have_http_status(:too_many_requests)
    expect(response.media_type).to eq('text/html')
  end

  {
    'sign-ups' => ['SIGN_UPS', :post, '/users'],
    'plan sharing' => ['INVITATIONS', :post, '/roles'],
    'invitations' => ['INVITATIONS', :post, '/users/invitation'],
    'ORCID logins' => ['OMNIAUTH', :get, '/users/auth/orcid/callback'],
    'password resets' => ['PASSWORD_RESETS', :post, '/users/password']
  }.each do |what, (name, verb, path)|
    it "limits #{what} per address" do
      lower_limit(name, to: 2)
      2.times { attempt(verb, path, '198.51.100.40') }
      attempt(verb, path, '198.51.100.40')

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
