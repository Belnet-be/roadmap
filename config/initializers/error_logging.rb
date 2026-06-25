# frozen_string_literal: true

# ============================================================
# Exception logging naar error.log via ActiveSupport::Notifications
# ============================================================

return unless ENV["BELNET_SPLITTED_LOGS"].to_s == "true"

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
  event     = ActiveSupport::Notifications::Event.new(*args)
  payload   = event.payload
  exception = payload[:exception]

  next unless exception

  exception_name    = exception.first
  exception_message = exception.last
  request_id        = begin
    payload[:headers]&.fetch('X-Request-Id', '-')
  rescue StandardError
    '-'
  end
  controller        = payload[:controller]
  action            = payload[:action]
  status            = payload[:status] || 500

  ERROR_LOGGER.error(
    "#{request_id} | #{exception_name} | #{exception_message} | " \
    "#{controller}##{action} | HTTP #{status}"
  )
end

Thread.report_on_exception = true if Rails.env.production?
