# frozen_string_literal: true

module Api
  module Belnet
    module V1
      # Handles retrieval and updates of a plan's lifecycle stage for Belnet API V1
      class LifecycleStagesController < BaseApiController
        respond_to :json

        # GET /api/belnet-v1/plans/:plan_id/lifecycle-stage
        def show
          plan = find_plan
          return unless plan

          lifecycle_stage = plan.current_lifecycle_stage_name

          if lifecycle_stage.present?
            render_lifecycle_stage(plan: plan, lifecycle_stage: lifecycle_stage, status: :ok)
          else
            render_error(errors: [_('Lifecycle stage not found')], status: :not_found)
          end
        end

        # POST /api/belnet-v1/plans/:plan_id/lifecycle-stage
        # Adds an initial lifecycle stage to an editable (live) DMP that has none yet.
        def create
          plan = find_plan
          return unless plan

          unless plan.is_plan_live_version?
            render_error(errors: [_('Lifecycle stage can only be added to an editable DMP')],
                         status: :bad_request)
            return
          end

          if plan.current_lifecycle_stage_name.present?
            render_error(errors: [_('Lifecycle stage already exists. Use PUT to update it.')],
                         status: :bad_request)
            return
          end

          stage_name = resolve_stage(plan)
          return unless stage_name

          acting_user = client.is_a?(User) ? client : nil
          unless plan.update_stage(stage_name, acting_user)
            render_error(errors: [_('Failed to add lifecycle stage')], status: :unprocessable_entity)
            return
          end

          plan.reload
          render_lifecycle_stage(plan: plan, lifecycle_stage: plan.current_lifecycle_stage_name,
                                 status: :created)
        end

        # PUT /api/belnet-v1/plans/:plan_id/lifecycle-stage
        def update
          plan = find_plan
          return unless plan

          stage_name = resolve_stage(plan)
          return unless stage_name

          acting_user = client.is_a?(User) ? client : nil

          # already at the requested stage.
          if plan.current_lifecycle_stage_name == stage_name
            render_lifecycle_stage(plan: plan, lifecycle_stage: stage_name, status: :accepted)
            return
          end

          unless plan.update_stage(stage_name, acting_user)
            render_error(errors: [_('Failed to update lifecycle stage')], status: :unprocessable_entity)
            return
          end

          plan.reload
          render_lifecycle_stage(plan: plan, lifecycle_stage: plan.current_lifecycle_stage_name,
                                 status: :accepted)
        end

        private

        def find_plan
          scope = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
          plan = scope.includes(
            { belnet_editable_plan_metadata: [
              { created_by: :identifiers },
              { updated_by: :identifiers }
            ] },
            :belnet_version_metadata,
            { roles: { user: :identifiers } },
            { belnet_stage_histories: { user: :identifiers } }
          ).where(id: params[:plan_id]).first

          return plan if plan

          render_error(errors: [_('Plan not found')], status: :not_found)
          nil
        end

        def resolve_stage(plan)
          stage_name = params[:'lifecycle-stage'].to_s.strip
          if stage_name.blank?
            render_error(errors: [_('lifecycle-stage is required')], status: :bad_request)
            return nil
          end

          return stage_name if plan.org&.current_valid_belnet_stages&.include?(stage_name)

          render_error(errors: [_('Lifecycle stage not found')], status: :bad_request)
          nil
        end

        def render_lifecycle_stage(plan:, lifecycle_stage:, status:)
          render 'api/belnet/v1/plans/lifecycle-stage/show', status: status,
                                                             locals: { plan: plan,
                                                                       lifecycle_stage: lifecycle_stage }
        end
      end
    end
  end
end
