# frozen_string_literal: true

module Api
  module Belnet
    module V1
      module Configurations
        # Exposes the belnet_config_validation_topics row that applies to the
        # caller. Users see their org's config when one exists; otherwise the
        # global (org_id IS NULL) row is returned.
        #
        # When an optional `plan-id` query parameter is provided, the
        # configuration is resolved against the organization of that plan
        # instead of the caller's own org. Access to that plan is enforced
        # through Api::Belnet::V1::PlansPolicy::Scope, so only callers with
        # UI-level access to the plan (contributor, owner, org-visible or
        # org admin) can use it.
        class ValidationTopicsController < BaseApiController
          respond_to :json

          # GET /api/belnet-v1/configurations/validation-topics
          # GET /api/belnet-v1/configurations/validation-topics?plan-id=123
          def show
            org = resolve_org
            return if performed?

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

          # Returns the org whose configuration should be returned:
          # * plan.org when a `plan-id` query parameter is provided and the
          #   caller has access to that plan;
          # * the caller's own org otherwise.
          # Renders a 404 (and returns nil) when a `plan-id` is provided but
          # the caller cannot access it.
          def resolve_org
            plan_id = params[:'plan-id']
            return caller_org if plan_id.blank?

            plan = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan)
                                                     .resolve
                                                     .find_by(id: plan_id)
            unless plan
              render_error(errors: [_('Plan not found')], status: :not_found)
              return nil
            end

            plan.org
          end

          def caller_org
            client.respond_to?(:org) ? client.org : nil
          end
        end
      end
    end
  end
end
