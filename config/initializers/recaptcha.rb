# frozen_string_literal: true

require 'recaptcha/rails'

# the keys are set in config/credentials.yml.env

Recaptcha.configure do |config|
  # config.site_key = ENV["BELNET_RECAPTCHA_SITE_KEY"] || Rails.application.credentials.recaptcha[:site_key]
  # config.secret_key = ENV["BELNET_RECAPTCHA_SECRET_KEY"] || Rails.application.credentials.recaptcha[:secret_key]
  config.site_key = ENV["RECAPTCHA_SITE_KEY"]
  config.secret_key = ENV["RECAPTCHA_SECRET_KEY"]
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://someproxy.com:port'
end
