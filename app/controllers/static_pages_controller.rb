# frozen_string_literal: true

# Controller that handles requests for static pages
class StaticPagesController < ApplicationController
  include ActionView::Helpers::DateHelper

  def about_us; end

  def contact_us; end

  def privacy; end

  def termsuse; end

  def help; end

  def version
    @app_name = ApplicationService.application_name
    @provider = Rails.configuration.x.organisation.name
    @ruby_version = RUBY_VERSION
    @rails_version = Rails.version
    @app_version = ENV.fetch('BELNET_DMPONLINE_VERSION', 'Unknown')
    @build_date = "#{BOOTED_AT.strftime('%Y-%m-%d %H:%M:%S %Z')} (#{time_ago_in_words(BOOTED_AT)} ago)"
    @app_based_on = {
      'name' => 'DMPRoadmap v5.0.2',
      'url' => 'https://github.com/DMPRoadmap/roadmap/releases/tag/v5.0.2'
    }
    # We get the list of js dependencies from package.json
    @js_dependencies = parse_package_json
    # We get the list of ruby gems straight from bundler
    @gems = Bundler.load.specs.map do |spec|
      { name: spec.name, version: spec.version.to_s }
    end.sort_by { |gem| gem[:name].downcase }
  end

  def api_documentation_overview
  end

  def api_documentation_v0
  end

  def api_documentation_v1
  end

  def belnet_changelog
  end

  private

  def parse_package_json
    # Get the actual path of packagejson
    package_json_path = Rails.root.join('package.json')
    return [] unless File.exist?(package_json_path)

    begin
      # parse the package.json file
      package_data = JSON.parse(File.read(package_json_path))
      dependencies = []

      # Merge dependencies and devDependencies
      %w[dependencies devDependencies].each do |key|
        next unless package_data[key]

        package_data[key].each do |name, version|
          dependencies << { name: name, version: version }
        end
      end

      dependencies.sort_by { |d| d[:name].downcase }
    rescue JSON::ParserError
      []
    end
  end
end
