# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'branded/layouts/_navigation', type: :view do
  context 'when DMP_ENVIRONMENT is set to DEV' do
    before do
      ENV['DMP_ENVIRONMENT'] = 'DEV'
      render partial: 'branded/layouts/navigation'
    end

    it 'has DMP_ENVIRONMENT assigned' do
      expect(ENV.fetch('DMP_ENVIRONMENT', nil)).to eq('DEV')
    end

    it 'displays the DEV environment banner' do
      expect(rendered).to have_selector('li.nav-item span.belnet-environment-banner__text', text: 'DEV')
    end

    it 'renders the navbar with the correct structure and classes' do
      puts rendered
      expect(rendered).to have_selector('nav#app-navbar.navbar.navbar-expand-md')
    end
  end
end
