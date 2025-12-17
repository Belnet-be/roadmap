require 'rails_helper'

RSpec.describe 'branded/layouts/_navigation', type: :view do
  before do
    # Set the .env variables for testing
    allow(ENV).to receive(:fetch).with('DMP_ENVIRONMENT', nil).and_return(nil)
  end

  context 'when DMP_ENVIRONMENT is set to DEV' do
    before do
      allow(ENV).to receive(:fetch).with('DMP_ENVIRONMENT', nil).and_return('DEV')
      render partial: 'branded/layouts/navigation'
    end

    it 'displays the DEV environment banner' do
      expect(rendered).to have_selector('li.nav-item span.belnet-environment-banner__text', text: 'DEV')
    end

    it 'applies correct navbar background color for DEV' do
      expect(rendered).to have_selector('nav.navbar.belnet-navbar--bg-dev')
    end
  end
end
