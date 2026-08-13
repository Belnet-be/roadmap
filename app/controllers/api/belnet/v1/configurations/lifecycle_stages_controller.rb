# frozen_string_literal: true

module Api
  module Belnet
    module V1
      module Configurations
        # Exposes the belnet_config_lifecycle_stages row that applies to the
        # caller. Users see their org's config when one exists; otherwise the
        # global (org_id IS NULL) row is returned.
        class LifecycleStagesController < BaseApiController
          respond_to :json

          # GET /api/belnet-v1/configurations/lifecycle-stages
          def show
            org = caller_org
            config = BelnetConfigLifecycleStage.for_org(org)

            unless config
              render_error(errors: [_('No lifecycle-stage configuration found')],
                           status: :not_found)
              return
            end

            render 'api/belnet/v1/configurations/lifecycle_stages/show',
                   status: :ok,
                   locals: { config: config, org: config.org }
          end

          private

          # ApiClients typically don't have an org; users always do.
          def caller_org
            client.respond_to?(:org) ? client.org : nil
          end
        end
      end
    end
  end
end
