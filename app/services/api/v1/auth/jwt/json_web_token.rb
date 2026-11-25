# frozen_string_literal: true

module Api
  module V1
    module Auth
      module Jwt
        # Class to handle encryption/descryption of the JWT
        class JsonWebToken
          # Tokens are signed and checked with this algorithm only
          ALGORITHM = 'HS256'

          class << self
            def encode(payload:, exp: 24.hours.from_now)
              payload[:exp] = exp.to_i
              JWT.encode(payload, Rails.application.secret_key_base, ALGORITHM)
            rescue JWT::EncodeError => e
              Rails.logger.error "Api::V1::Auth::Jwt::JsonWebToken.encode - #{e.message}"
              nil
            end

            def decode(token:)
              body = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: ALGORITHM)[0]
              ActiveSupport::HashWithIndifferentAccess.new body
            rescue JWT::ExpiredSignature => e
              raise e
            rescue JWT::DecodeError => e
              Rails.logger.error "Api::V1::Auth::Jwt::JsonWebToken.decode - #{e.message}"
              nil
            end

            # A fingerprint of the credentials a token is issued for: an API client's secret or a
            # user's API token. Tokens carry it, and a token only works while it still matches, so
            # rotating the credentials revokes every token issued before at once instead of at its
            # expiry. Keyed with secret_key_base: the token does not reveal anything about the secret.
            def credentials_fingerprint(client)
              secret = client.is_a?(ApiClient) ? client.client_secret : client.try(:api_token)
              return nil if client.nil? || secret.blank?

              OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base,
                                      "#{client.class.name}:#{client.id}:#{secret}")
            end
          end
        end
      end
    end
  end
end
