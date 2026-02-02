# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'branded/static_pages/api_documentation_overview', type: :view do
  it 'renders the page and displays tabs in an ul with classes "nav nav-tabs"' do
    render

    expect(rendered).to have_selector('ul.nav.nav-tabs')
  end
end
