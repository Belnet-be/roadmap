# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'branded/static_pages/api_documentation_v1', type: :view do
  it 'renders the page and displays tabs in an ul with classes "nav nav-tabs"' do
    render

    expect(rendered).to have_selector('ul.nav.nav-tabs')
    expect(rendered).to have_selector('h2.mt-4', text: 'Using the API')
  end
end
