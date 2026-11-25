# frozen_string_literal: true

# NB: `req` is a Rack::Request object (basically an env hash with friendly accessor methods)

# Enable/disable Rack::Attack. Off in the test suite, which sends many requests from one address;
# spec/requests/rate_limits_spec.rb switches it on for its own examples.
Rack::Attack.enabled = !Rails.env.test?

# Cache store required to work.
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new # defaults to Rails.cache

# The limits below can be changed without a release: RACK_ATTACK_<NAME>_LIMIT, e.g.
# RACK_ATTACK_API_LIMIT=600. They are read on every request.
rate_limit = ->(name, default) { Integer(ENV.fetch("RACK_ATTACK_#{name}_LIMIT", default)) }

# Throttle should send a 429 Error responsec code and display public/429.html, or a JSON error for
# the API. Retry-After tells the client when it may try again.
Rack::Attack.throttled_responder = lambda do |request|
  match = request.env['rack.attack.match_data'] || {}
  headers = {}
  headers['Retry-After'] = (match[:period] - (match[:epoch_time] % match[:period])).to_s if match[:period]

  if request.path.start_with?('/api/')
    [429, headers.merge('Content-Type' => 'application/json'), [{ errors: ['Too many requests'] }.to_json]]
  else
    html = ActionView::Base.empty.render(file: 'public/429.html')
    [429, headers.merge('Content-Type' => 'text/html'), [html]]
  end
end

# Throttle attempts to a particular path. 2 POSTs to /users/password every 30 seconds
Rack::Attack.throttle 'password_resets/ip', limit: ->(_req) { rate_limit.call('PASSWORD_RESETS', 2) },
                                            period: 30.seconds do |req|
  req.post? && req.path == '/users/password' && req.ip
end

# Throttle attempts to a particular path. 4 POSTs to /users/sign_in every 30 seconds
Rack::Attack.throttle 'logins/ip', limit: ->(_req) { rate_limit.call('LOGINS', 4) }, period: 30.seconds do |req|
  req.post? && req.path == '/users/sign_in' && req.ip
end

# New accounts: 20 sign-ups per address every 10 minutes
Rack::Attack.throttle 'sign_ups/ip', limit: ->(_req) { rate_limit.call('SIGN_UPS', 20) },
                                     period: 10.minutes do |req|
  req.post? && req.path == '/users' && req.ip
end

# Sharing a plan and inviting people send mails: 30 per address every 10 minutes
Rack::Attack.throttle 'invitations/ip', limit: ->(_req) { rate_limit.call('INVITATIONS', 30) },
                                        period: 10.minutes do |req|
  req.post? && ['/roles', '/users/invitation'].include?(req.path) && req.ip
end

# ORCID and Shibboleth logins: 30 per address every minute
Rack::Attack.throttle 'omniauth/ip', limit: ->(_req) { rate_limit.call('OMNIAUTH', 30) }, period: 1.minute do |req|
  req.path.start_with?('/users/auth/') && req.ip
end

# API tokens: 10 requests for a token per address every minute
Rack::Attack.throttle 'api_authentications/ip', limit: ->(_req) { rate_limit.call('API_AUTHENTICATIONS', 10) },
                                                period: 1.minute do |req|
  req.post? && req.path == '/api/v1/authenticate' && req.ip
end

# All API calls: 300 per address every 5 minutes
Rack::Attack.throttle 'api/ip', limit: ->(_req) { rate_limit.call('API', 300) }, period: 5.minutes do |req|
  req.path.start_with?('/api/') && req.ip
end
