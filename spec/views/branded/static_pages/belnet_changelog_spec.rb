# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'branded/static_pages/belnet_changelog', type: :view do
  it 'parses markdown to html' do
    render

    expect(rendered).to match(%r{<ul>\s*<li>.*</li>\s*</ul>})
  end
end
