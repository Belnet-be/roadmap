# frozen_string_literal: true

module Api
  module Belnet
    module V1
      # Handles CRUD operations for versions in API V1 for Belnet
      class VersionsController < BaseApiController
        respond_to :json

        # GET /api/belnet/v1/versions
        def index
          # This endpoint should return a collection of plans that are associated to the given plan
          # by their family_id (column: belnet_family_id).
          plan = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
                                                    .where(id: params[:id])
                                                    .first
          if plan
            plans = plan.plan_versions_with_live_version
                        .order(belnet_version: :desc)

            @items = if plans.present? && plans.any?
                       paginate_response(results: plans)
                     else
                       paginate_response(results: Plan.none)
                     end
            render '/api/belnet/v1/plans/index', status: :ok

          else
            render_error(errors: [_('Plan not found')], status: :not_found)
          end
        end

        # POST /api/belnet/v1/versions
        def create
          # This endpoint should create a new version of a plan given that the plan in question's belnet_version
          # is 0 (This means it's the LIVE version).
          plan = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
                                                    .where(id: params[:id])
                                                    .first

          if plan.present? && plan.is_plan_live_version?
            plan.create_plan_with_new_version!(reason: params[:reason], current_user: current_user, original_plan: plan)
            render '/api/belnet/v1/plans/index', status: :created
          else
            render_error(errors: [_('Plan not found or not eligible for versioning')], status: :not_found)
          end
        end
      end
    end
  end
end
