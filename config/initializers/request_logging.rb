# frozen_string_literal: true

# ============================================================
# Request logging middleware — DMP Roadmap
# ============================================================
#
# Logt elke HTTP request naar:
#   CLIENT_LOGGER → log/client.log  (alle requests)
#   ERROR_LOGGER  → log/error.log   (4xx/5xx)
#
# Belangrijk: status.to_i is verplicht.
# Rack garandeert niet dat status altijd een Integer is.
# Zonder .to_i crasht ">= 400" met NoMethodError wanneer
# status een String of wrapped object is (Dragonfly/OmniAuth).
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

    # Expliciete cast naar Integer — voorkomt NoMethodError
    http_status = status.to_i

    CLIENT_LOGGER.info(
      "#{request_id} | #{req.request_method} #{req.fullpath} | " \
      "#{http_status} | #{duration}ms | #{req.ip} | #{referer} | #{user_agent}"
    )

    if http_status >= 400
      ERROR_LOGGER.warn(
        "#{request_id} | HTTP #{http_status} | " \
        "#{req.request_method} #{req.fullpath} | ip=#{req.ip}"
      )
    end

    [status, headers, response]
  end
end

Rails.application.config.middleware.insert_after(
  ActionDispatch::RequestId,
  RequestLogger
)
