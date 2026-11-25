# frozen_string_literal: true

require 'rails_helper'

# An ORCID iD only gives access to accounts it was linked to through an ORCID login. ORCID iDs
# that came in as data (for example a DMP contact sent through the API) never give access, and
# there is no way to switch to another account without signing in to it.
RSpec.describe 'Account access with ORCID', type: :request do
  let(:orcid_uid) { '0000-0002-1825-0097' }

  # Belnet's User before_validation sets the org from the email domain and falls back to
  # Org.guest, so the guest org has to exist for users to be valid.
  before { create(:org, abbreviation: 'guests') unless Org.guest.present? }

  let!(:scheme) do
    IdentifierScheme.find_by(name: 'orcid') ||
      create(:identifier_scheme, name: 'orcid', identifier_prefix: 'https://orcid.org/',
                                 context_count: 0, for_authentication: true, for_users: true)
  end

  # The callback controller defines one action per login scheme when its class loads, based on
  # the database. The test database is empty at that moment, so define the ORCID action here.
  # OmniAuth's test mode then hands the controller the mocked ORCID answer.
  around do |example|
    Users::OmniauthCallbacksController.define_method(:orcid) do
      handle_omniauth(IdentifierScheme.find_by(name: 'orcid'))
    end
    OmniAuth.config.test_mode = true
    example.run
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:orcid] = nil
  end

  # A link made through an ORCID login stores ORCID's own answer; imported data has none.
  def link_orcid(user, verified:)
    attrs = verified ? { 'provider' => 'orcid', 'uid' => orcid_uid, 'info' => {} } : {}
    Identifier.create!(identifier_scheme: scheme, value: orcid_uid, attrs: attrs, identifiable: user)
  end

  def sign_in_with_orcid(email:)
    OmniAuth.config.mock_auth[:orcid] = OmniAuth::AuthHash.new(
      provider: 'orcid', uid: orcid_uid,
      info: { email: email, first_name: 'Test', last_name: 'Person' }
    )
    get '/users/auth/orcid/callback'
  end

  # The user signed in by the last request, or nil (a refused login ends in Devise's failure app)
  def current_user
    controller.respond_to?(:current_user) ? controller.current_user : nil
  end

  describe 'switching to another account' do
    it 'has no switch user pages' do
      sign_in create(:user)
      expect { get '/switch_user/edit' }.to raise_error(ActionController::RoutingError)
      expect { post '/switch_user', params: { user: { id: 1 } } }.to raise_error(ActionController::RoutingError)
    end

    it 'has no switch user link, even for accounts that share an ORCID iD' do
      user = create(:user)
      link_orcid(user, verified: true)
      link_orcid(create(:user), verified: true)
      sign_in user

      get '/plans'

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Switch user')
    end
  end

  describe 'signing in with ORCID' do
    context 'when the ORCID iD is on an account only as imported data' do
      let!(:victim) { create(:user) }
      let!(:private_plan) { create(:plan).tap { |plan| plan.add_user!(victim.id, :creator) } }

      before { link_orcid(victim, verified: false) }

      it "doesn't sign in to that account" do
        sign_in_with_orcid(email: 'someone.else@example.org')

        expect(current_user).not_to eq(victim)
        expect(current_user&.email).to eq('someone.else@example.org')
      end

      it "keeps that account's private plan out of reach" do
        sign_in_with_orcid(email: 'someone.else@example.org')
        get "/plans/#{private_plan.id}"

        expect(response).not_to have_http_status(:ok)
      end

      it "doesn't offer that account on the account choice page" do
        own_account = create(:user)
        link_orcid(own_account, verified: true)

        sign_in_with_orcid(email: 'someone.else@example.org')
        post '/selectable_user', params: { selectable_user: { id: victim.id } }

        expect(current_user).not_to eq(victim)
      end
    end

    context 'when the ORCID iD was linked through an ORCID login' do
      it 'signs in to that account' do
        user = create(:user)
        link_orcid(user, verified: true)

        sign_in_with_orcid(email: 'someone.else@example.org')

        expect(current_user).to eq(user)
      end

      it 'lets the person choose between their linked accounts' do
        first_account = create(:user)
        second_account = create(:user)
        link_orcid(first_account, verified: true)
        link_orcid(second_account, verified: true)

        sign_in_with_orcid(email: 'someone.else@example.org')
        expect(response).to redirect_to('/selectable_user/edit')
        get '/selectable_user/edit'
        expect(response.body).to include(first_account.email, second_account.email)
        post '/selectable_user', params: { selectable_user: { id: second_account.id } }

        expect(current_user).to eq(second_account)
      end

      it "doesn't sign in to a deactivated account" do
        user = create(:user, active: false)
        link_orcid(user, verified: true)

        sign_in_with_orcid(email: 'someone.else@example.org')

        expect(current_user).not_to eq(user)
      end
    end

    context 'when an older, unconfirmed ORCID iD is on the account' do
      it 'signs in when ORCID confirms the account email, and records the confirmation' do
        user = create(:user)
        link = link_orcid(user, verified: false)

        sign_in_with_orcid(email: user.email)

        expect(current_user).to eq(user)
        expect(link.reload.verified_orcid_link?).to be(true)
      end

      it 'records the confirmation when the user links ORCID from their profile' do
        user = create(:user)
        link = link_orcid(user, verified: false)
        sign_in user

        sign_in_with_orcid(email: 'someone.else@example.org')

        expect(link.reload.verified_orcid_link?).to be(true)
      end
    end
  end
end
