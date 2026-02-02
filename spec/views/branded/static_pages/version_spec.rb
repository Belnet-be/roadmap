# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'branded/static_pages/version', type: :view do
  it 'displays the application technical info' do
    # set this dynamically in the future?
    assign(:app_name, 'DMPonline.be')
    assign(:provider, 'Belnet')
    assign(:app_version, 'belnet_main')
    assign(:ruby_version, '3.1.4')
    assign(:rails_version, '7.1.5.2')
    assign(:build_date, '2026-02-02 07:45:26 UTC (about 7 hours ago)')
    assign(:app_based_on, {
             'name' => 'DMPRoadmap v5.0.2',
             'url' => 'https://github.com/DMPRoadmap/roadmap/releases/tag/v5.0.2'
           })

    render

    # expect section
    expect(rendered).to have_selector('dt', text: 'Application Name:')
    expect(rendered).to have_content('DMPonline.be')

    expect(rendered).to have_selector('dt', text: 'Provider:')
    expect(rendered).to have_content('Belnet')

    expect(rendered).to have_selector('dt', text: 'Application Version:')
    expect(rendered).to have_content('belnet_main')

    expect(rendered).to have_selector('dt', text: 'Ruby Version:')
    expect(rendered).to have_content('3.1.4')

    expect(rendered).to have_selector('dt', text: 'Rails Version:')
    expect(rendered).to have_content('7.1.5.2')

    expect(rendered).to have_selector('dt', text: 'Last Deployment:')
    expect(rendered).to have_content('2026-02-02 07:45:26 UTC')
  end
end
