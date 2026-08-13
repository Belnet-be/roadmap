# frozen_string_literal: true

module Api
  module Belnet
    module V1
      module Configurations
        # Exposes the belnet_config_validation_topics row that applies to the
        # caller. Users see their org's config when one exists; otherwise the
        # global (org_id IS NULL) row is returned.
        class ValidationTopicsController < BaseApiController
          respond_to :json

          # GET /api/belnet-v1/configurations/validation-topics
          def show
            org = caller_org
            config = BelnetConfigValidationTopic.for_org(org)

            unless config
              render_error(errors: [_('No validation-topic configuration found')],
                           status: :not_found)
              return
            end

            render 'api/belnet/v1/configurations/validation_topics/show',
                   status: :ok,
                   locals: { config: config, org: config.org }
          end

          private

          def caller_org
            client.respond_to?(:org) ? client.org : nil
          end
        end
      end
    end
  end
end
