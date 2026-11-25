# frozen_string_literal: true

require 'rails_helper'

# Only super admins may refresh or email an API client's credentials, these actions only change
# anything on a write request with a valid CSRF token, and other callers can't find out which
# API client IDs exist.
RSpec.describe 'Super admin API client credentials', type: :request do
  # Belnet's User before_validation sets the org from the email domain and falls back to
  # Org.guest, so the guest org has to exist for factory users to be valid.
  before { create(:org, abbreviation: 'guests') unless Org.guest.present? }

  let!(:api_client) { create(:api_client) }
  let!(:original_id) { api_client.client_id }
  let!(:original_secret) { api_client.client_secret }

  let(:js) { { 'Accept' => 'text/javascript, application/javascript' } }
  let(:refresh_path) { "/super_admin/api_clients/#{api_client.id}/refresh_credentials" }
  let(:email_path) { "/super_admin/api_clients/#{api_client.id}/email_credentials" }

  # Sends the request like the browser would (XHR) and returns the response body. A routing,
  # format or CSRF error counts as a rejected request, so it returns an empty body.
  def attempt(verb, path, headers: js, xhr: true)
    send(verb, path, headers: headers, xhr: xhr)
    response.body.to_s
  rescue ActionController::RoutingError, ActionController::UnknownFormat,
         ActionController::InvalidAuthenticityToken
    ''
  end

  def expect_credentials_unchanged(body)
    expect(api_client.reload.slice(:client_id, :client_secret))
      .to eq('client_id' => original_id, 'client_secret' => original_secret)
    expect(body).not_to include(original_secret)
  end

  def authenticate_status(client_id, client_secret)
    post '/api/v1/authenticate',
         params: { grant_type: 'client_credentials', client_id: client_id,
                   client_secret: client_secret }.to_json,
         headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    response.status
  end

  def deliveries
    ActionMailer::Base.deliveries.size
  end

  shared_examples 'cannot use the credential actions' do
    %i[get head patch post put].each do |verb|
      it "can't refresh the credentials with #{verb.upcase}" do
        body = attempt(verb, refresh_path, xhr: true, headers: js)
        expect_credentials_unchanged(body)
      end
    end

    it "can't have the credentials emailed" do
      expect do
        %i[get post].each { |verb| attempt(verb, email_path, xhr: true, headers: js) }
      end.not_to(change { deliveries })
    end
  end

  context 'when not signed in' do
    it_behaves_like 'cannot use the credential actions'
  end

  context 'when signed in as a regular user' do
    before { sign_in create(:user) }

    it_behaves_like 'cannot use the credential actions'
  end

  context 'when signed in as an org admin' do
    before { sign_in create(:user, :org_admin) }

    it_behaves_like 'cannot use the credential actions'
  end

  context 'when signed in as a super admin' do
    before { sign_in create(:user, :super_admin) }

    it 'refreshes the credentials with PATCH and shows the new pair' do
      patch refresh_path, xhr: true, headers: js

      expect(response).to have_http_status(:ok)
      api_client.reload
      expect(api_client.client_id).not_to eq(original_id)
      expect(api_client.client_secret).not_to eq(original_secret)
      expect(response.body).to include(api_client.client_secret)
      expect(authenticate_status(original_id, original_secret)).to eq(401)
      expect(authenticate_status(api_client.client_id, api_client.client_secret)).to eq(200)
    end

    it "doesn't refresh the credentials on a GET request" do
      body = attempt(:get, refresh_path, xhr: true, headers: js)
      expect_credentials_unchanged(body)
    end

    it 'emails the credentials to the contact with POST' do
      expect { post email_path, xhr: true, headers: js }.to change { deliveries }.by(1)
      expect(ActionMailer::Base.deliveries.last.to).to include(api_client.contact_email)
    end

    it "doesn't email the credentials on a GET request" do
      expect { attempt(:get, email_path, xhr: true, headers: js) }.not_to(change { deliveries })
    end

    context 'with CSRF protection on, as in production' do
      around do |example|
        ActionController::Base.allow_forgery_protection = true
        example.run
      ensure
        ActionController::Base.allow_forgery_protection = false
      end

      it 'rejects a refresh without a valid authenticity token' do
        body = attempt(:patch, refresh_path, xhr: true, headers: js)
        expect_credentials_unchanged(body)
      end

      it 'rejects an email request without a valid authenticity token' do
        expect { attempt(:post, email_path, xhr: true, headers: js) }.not_to(change { deliveries })
      end

      it 'still works from the edit page, which sends the CSRF token like the browser does' do
        get "/super_admin/api_clients/#{api_client.id}/edit"
        expect(response).to have_http_status(:ok)
        page = Nokogiri::HTML(response.body)
        expect(page.at_css("a[href='#{refresh_path}']")['data-method']).to eq('patch')
        expect(page.at_css("a[href='#{email_path}']")['data-method']).to eq('post')
        token = page.at_css('meta[name="csrf-token"]')['content']

        patch refresh_path, xhr: true, headers: js.merge('X-CSRF-Token' => token)

        expect(response).to have_http_status(:ok)
        expect(api_client.reload.client_secret).not_to eq(original_secret)
      end
    end
  end

  describe 'probing which API client IDs exist' do
    let(:json) { { 'Accept' => 'application/json' } }

    def status_for(id)
      attempt(:get, "/super_admin/api_clients/#{id}/edit", headers: json, xhr: false)
      response.status
    end

    it 'gives the same answer for an existing and a missing ID when not signed in' do
      expect(status_for(api_client.id)).to eq(status_for(999_999_999))
    end

    it 'gives the same answer for an existing and a missing ID to a regular user' do
      sign_in create(:user)
      expect(status_for(api_client.id)).to eq(status_for(999_999_999))
    end
  end
end
