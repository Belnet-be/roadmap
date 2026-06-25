# frozen_string_literal: true

# ============================================================
# Gesplitste logging — DMP Roadmap
# ============================================================
#
# Dit bestand definieert enkel de file loggers als constanten.
# Rails.logger wordt NIET aangeraakt — dat gebeurt correct
# in config/environments/production.rb via RAILS_LOG_TO_STDOUT.
#
# De BroadcastLogger (stdout + bestanden) wordt ingesteld via
# config/application.rb after_initialize, nadat production.rb
# zijn logger heeft aangemaakt.
#
# Logbestanden:
#   log/client.log   — HTTP requests (INFO+)
#   log/error.log    — 4xx/5xx en exceptions (WARN+)
#   log/db.log       — SQL queries via ActiveRecord (DEBUG+)
#   log/security.log — Rack::Attack events (WARN+)
# ============================================================

return unless ENV["BELNET_SPLITTED_LOGS"].to_s == "true"

module DmpRoadmap
  module Logging
    # --------------------------------------------------------
    # Formatter: [2026-05-13 08:00:00] [INFO ] [PID 123] msg
    # --------------------------------------------------------
    FORMATTER = proc do |severity, time, _progname, msg|
      "[#{time.strftime('%Y-%m-%d %H:%M:%S')}] [#{severity.ljust(5)}] [PID #{Process.pid}] #{msg}\n"
    end

    # --------------------------------------------------------
    # Helper: maak een file logger aan
    # Geen TaggedLogging wrapper — veroorzaakt NoMethodError
    # bij status >= 400 in Rack middleware.
    # --------------------------------------------------------
    def self.build(filename, shift_age: 7, shift_size: 50 * 1024 * 1024)
      path   = Rails.root.join('log', filename)
      logger = Logger.new(path, shift_age, shift_size)
      logger.formatter = FORMATTER
      logger
    end
  end
end

# --------------------------------------------------------
# File loggers — beschikbaar als globale constanten
# voor gebruik in request_logging.rb middleware
# --------------------------------------------------------
CLIENT_LOGGER         = DmpRoadmap::Logging.build('client.log')
CLIENT_LOGGER.level   = Logger::INFO

ERROR_LOGGER          = DmpRoadmap::Logging.build('error.log')
ERROR_LOGGER.level    = Logger::WARN

DB_LOGGER             = DmpRoadmap::Logging.build('db.log')
DB_LOGGER.level       = Logger::DEBUG

SECURITY_LOGGER       = DmpRoadmap::Logging.build('security.log')
SECURITY_LOGGER.level = Logger::WARN

# --------------------------------------------------------
# ActiveRecord → DB logger
# --------------------------------------------------------
ActiveRecord::Base.logger = DB_LOGGER if defined?(ActiveRecord)

# --------------------------------------------------------
# Rack::Attack → Security logger
# --------------------------------------------------------
ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _id, payload|
  req        = payload[:request]
  match_type = req.env['rack.attack.match_type']
  match_name = req.env['rack.attack.matched']

  SECURITY_LOGGER.warn(
    "rack_attack | #{match_type} | #{match_name} | " \
    "#{req.request_method} #{req.path} | ip=#{req.ip}"
  )
end
