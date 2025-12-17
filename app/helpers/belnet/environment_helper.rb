# frozen_string_literal: true

module Belnet
  module EnvironmentHelper
    def render_belnet_environment_banner
      environment = ENV.fetch('DMP_ENVIRONMENT', nil)
      return unless %w[DEV TEST INT].include?(environment)

      content_tag :li, class: 'nav-item' do
        concat content_tag(:span, environment, class: 'belnet-environment-banner__text')
      end
    end
  end
end
