# frozen_string_literal: true

# ============================================================
# Gesplitste logging configuratie
# ============================================================

return unless Rails.env.production? || ENV['RAILS_LOG_TO_STDOUT'].present?

module DmpRoadmap
  module Logging
    FORMATTER = proc do |severity, time, _progname, msg|
      timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
      "[#{timestamp}] [#{severity.ljust(5)}] [PID #{Process.pid}] #{msg}\n"
    end

    def self.build(filename, shift_age: 7, shift_size: 50 * 1024 * 1024)
      path   = Rails.root.join('log', filename)
      logger = Logger.new(path, shift_age, shift_size)
      logger.formatter = FORMATTER
      ActiveSupport::TaggedLogging.new(logger)
    end
  end
end

CLIENT_LOGGER = DmpRoadmap::Logging.build('client.log')
CLIENT_LOGGER.level = Logger::INFO

ERROR_LOGGER = DmpRoadmap::Logging.build('error.log')
ERROR_LOGGER.level = Logger::WARN

DB_LOGGER       = DmpRoadmap::Logging.build('db.log')
DB_LOGGER.level = Logger::DEBUG

SECURITY_LOGGER = DmpRoadmap::Logging.build('security.log')
SECURITY_LOGGER.level = Logger::WARN

ActiveRecord::Base.logger = DB_LOGGER if defined?(ActiveRecord)

ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _id, payload|
  req        = payload[:request]
  match_type = req.env['rack.attack.match_type']
  match_name = req.env['rack.attack.matched']

  SECURITY_LOGGER.warn(
    "rack_attack | #{match_type} | #{match_name} | #{req.request_method} #{req.path} | ip=#{req.ip}"
  )
end
