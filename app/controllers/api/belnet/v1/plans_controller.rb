# frozen_string_literal: true

module Api
  module Belnet
    module V1
      # Serves full DMP payloads (RDA Common Standard + belnet extension) for
      # both the editable/live plan and its immutable version snapshots. The
      # extension block varies per case; see the show view for details.
      class PlansController < BaseApiController
        respond_to :json

        # GET /api/belnet-v1/plans/:id
        # `id` may reference either the editable (LIVE) DMP or one of its
        # version snapshots. The response's `dmp/extension/belnet/dmp_extension_type`
        # tells the caller which flavor came back.
        def show
          scope = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
          plan = scope.includes(
            :template,
            :research_outputs,
            :belnet_version_metadata,
            { belnet_editable_plan_metadata: [
              { created_by: :identifiers },
              { updated_by: :identifiers }
            ] },
            { roles: { user: :identifiers } }
          ).find_by(id: params[:id])

          unless plan
            render_error(errors: [_('Plan not found')], status: :not_found)
            return
          end

          # dmp/dmp_id is always the LIVE DMP's identifier. Look it up now so
          # the view doesn't have to.
          live_plan = live_plan_for(plan)

          # dmp_validations: ALL validations for an editable DMP request, or
          # ONLY the ones targeting this specific version otherwise.
          validations = validations_for(plan, live_plan)

          render 'api/belnet/v1/plans/show', status: :ok, locals: {
            plan: plan,
            live_plan: live_plan,
            validations: validations
          }
        end

        private

        # Returns the LIVE DMP for the requested plan. `plan` itself when it
        # already is the live version; otherwise looked up by belnet_family_id.
        # Falls back to `plan` when no live sibling exists (defensive).
        def live_plan_for(plan)
          return plan if plan.is_plan_live_version?

          Plan.find_by(belnet_family_id: plan.belnet_family_id, belnet_version: 0) || plan
        end

        def validations_for(plan, live_plan)
          scope = live_plan.governance_validations
                           .includes(:validated_plan,
                                     { requested_by: :identifiers },
                                     { reviewed_by: :identifiers })
                           .order(created_at: :desc)

          # For a version request, only surface validations targeting this
          # specific version snapshot.
          scope = scope.where(validated_plan_id: plan.id) unless plan.is_plan_live_version?

          scope
        end
      end
    end
  end
end
