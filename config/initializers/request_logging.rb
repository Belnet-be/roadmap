# frozen_string_literal: true

# ============================================================
# Request logging middleware → client.log
# ============================================================

class RequestLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    start = Time.current
    status, headers, response = @app.call(env)
    duration = ((Time.current - start) * 1000).round(2)

    req        = Rack::Request.new(env)
    request_id = env['action_dispatch.request_id'] || '-'
    referer    = req.referer || '-'
    user_agent = req.user_agent || '-'

    CLIENT_LOGGER.info(
      "#{request_id} | #{req.request_method} #{req.fullpath} | " \
      "#{status} | #{duration}ms | #{req.ip} | #{referer} | #{user_agent}"
    )

    if status >= 400
      ERROR_LOGGER.warn(
        "#{request_id} | HTTP #{status} | #{req.request_method} #{req.fullpath} | ip=#{req.ip}"
      )
    end

    [status, headers, response]
  end
end

Rails.application.config.middleware.insert_after(
  ActionDispatch::RequestId,
  RequestLogger
)
