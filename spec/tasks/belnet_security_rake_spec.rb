# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# Older ORCID logins stored ORCID's access and refresh token; the task removes them and keeps the
# rest of ORCID's answer, so the link stays a confirmed ORCID link.
RSpec.describe 'rake belnet:security:remove_stored_login_tokens' do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('belnet:security:remove_stored_login_tokens')
  end

  let(:task) { Rake::Task['belnet:security:remove_stored_login_tokens'] }
  let(:uid) { '0000-0002-1825-0097' }
  let!(:scheme) do
    IdentifierScheme.find_by(name: 'orcid') ||
      create(:identifier_scheme, name: 'orcid', identifier_prefix: 'https://orcid.org/', context_count: 0,
                                 for_authentication: true, for_users: true)
  end

  # Belnet sets a new user's org from the email domain and falls back to Org.guest
  before do
    create(:org, abbreviation: 'guests') unless Org.guest.present?
    task.reenable
  end

  after { ENV.delete('APPLY') }

  let!(:with_tokens) do
    Identifier.create!(identifier_scheme: scheme, value: uid, identifiable: create(:user),
                       attrs: { 'provider' => 'orcid', 'uid' => uid,
                                'credentials' => { 'token' => 'access-token', 'refresh_token' => 'refresh-token' } })
  end
  # A newer ORCID link, and a Shibboleth-style answer with an empty "credentials"
  let!(:without_tokens) do
    Identifier.create!(identifier_scheme: scheme, value: '0000-0000-0000-0001', identifiable: create(:user),
                       attrs: { 'provider' => 'orcid', 'uid' => '0000-0000-0000-0001', 'credentials' => {} })
  end

  it 'only counts in a dry run' do
    expect { task.invoke }.to output(/found \(dry run.*\): 1 identifiers/).to_stdout
    expect(JSON.parse(with_tokens.reload.attrs)).to have_key('credentials')
  end

  it 'removes the tokens with APPLY=1 and keeps the rest of the ORCID answer' do
    ENV['APPLY'] = '1'
    untouched = without_tokens.attrs

    expect { task.invoke }.to output(/removed: 1 identifiers/).to_stdout
    attrs = JSON.parse(with_tokens.reload.attrs)
    expect(attrs).not_to have_key('credentials')
    expect(attrs).to include('provider' => 'orcid', 'uid' => uid)
    expect(with_tokens.verified_orcid_link?).to be(true)
    expect(without_tokens.reload.attrs).to eq(untouched)
  end
end
