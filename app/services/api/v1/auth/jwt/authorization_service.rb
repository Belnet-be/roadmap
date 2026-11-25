# frozen_string_literal: true

module Api
  module V1
    module Auth
      module Jwt
        # Class to handle User authorization
        class AuthorizationService
          def initialize(headers: {})
            @headers = headers.nil? ? {} : headers
            @errors = ActiveSupport::HashWithIndifferentAccess.new
          end

          def call
            client
          end

          attr_reader :errors

          private

          # Lookup the Client based on the client_id embedded in the JWT
          def client # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            return @api_client if @api_client.present?

            token = decoded_auth_token
            # If the token is missing or invalid then set the client to nil
            errors[:token] = _('Invalid token') unless token.present?
            @api_client = nil unless token.present? && token[:client_id].present?
            return @api_client unless token.present? && token[:client_id].present?

            @api_client = ApiClient.where(client_id: token[:client_id]).first
            return @api_client = current_credentials(token, @api_client) if @api_client.present?

            # Valid if User is active, has permission to use the API and
            # the :client_secret matches the token
            usr = User.where(email: token[:client_id], active: true).first
            @api_client = usr.present? && usr.can_use_api? ? current_credentials(token, usr) : nil
          end

          # The client, if the token was issued for its current credentials. Tokens issued before
          # the API client's secret or the user's API token changed, and tokens from before this
          # check (without a fingerprint), are refused.
          def current_credentials(token, client)
            expected = JsonWebToken.credentials_fingerprint(client)
            given = token[:cv]
            if expected.present? && given.is_a?(String) &&
               ActiveSupport::SecurityUtils.secure_compare(expected, given)
              return client
            end

            errors[:token] = _('Invalid token')
            nil
          end

          def decoded_auth_token
            return @token if @token.present?

            @token = JsonWebToken.decode(token: http_auth_header)
            @token
          rescue JWT::ExpiredSignature
            errors[:token] = _('Token expired')
            nil
          end

          # Extract the token from the Authorization header
          def http_auth_header
            hdr = @headers[:Authorization]
            errors[:token] = _('Missing token') unless hdr.present?
            return nil unless hdr.present?

            hdr.split.last
          end
        end
      end
    end
  end
end
