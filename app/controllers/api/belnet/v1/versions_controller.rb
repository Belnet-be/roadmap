# frozen_string_literal: true

module Api
  module Belnet
    module V1
      # Handles CRUD operations for versions in API V1 for Belnet
      class VersionsController < BaseApiController
        respond_to :json

        # GET /api/belnet/v1/plans/:plan_id/versions
        def index # rubocop:disable Metrics/AbcSize
          # This endpoint should return a collection of plans that are associated to the given plan
          # by their family_id (column: belnet_family_id).
          scope = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
          plan = scope.where(id: params[:plan_id]).first

          unless plan
            render_error(errors: [_('Plan not found')], status: :not_found)
            return
          end

          versions = scope.where(belnet_family_id: params[:plan_id])
                          .where('belnet_version > ?', 0)
                          .order(belnet_version: :desc)

          @view = params.fetch(:view, 'summary')
          @items = paginate_response(results: versions)
          render 'api/belnet/v1/versions/index', status: :ok
        end

        # GET /api/belnet/v1/plans/:plan_id/versions/:id (:id means version number in this case)
        def show # rubocop:disable Metrics/AbcSize
          if params[:id].present? && params[:id].to_i > 0
            plan = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
                                                      .where(id: params[:plan_id])
                                                      .first
            if plan
              version = plan.plan_versions
                            .where(belnet_version: params[:id])
                            .first

              if version
                render 'api/belnet/v1/plans/show', status: :ok, locals: { plan: version }
              else
                render_error(errors: [_('Version not found')], status: :not_found)
              end
            else
              render_error(errors: [_('Plan not found')], status: :not_found)
            end
          else
            # This is the live plan version
            render_error(errors: [_('Invalid version number')], status: :bad_request)
          end
        end

        # POST /api/belnet/v1/plans/:plan_id/versions
        def create
          # This endpoint should create a new version of a plan given that the plan in question's belnet_version
          # is 0 (This means it's the LIVE version).
          plan = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
                                                    .where(id: params[:plan_id])
                                                    .first
          stage = plan.org.belnet_stages.find_by(code: params[:stage_code])
          stage ||= plan.plan_versions.sort_by(&:belnet_version).last&.belnet_stage
          if plan.present? && plan.is_plan_live_version? && stage.present?
            new_version = plan.create_plan_with_new_version!(reason: params[:reason], current_user: current_user,
                                                             original_plan: plan, new_stage: stage)
            render 'api/belnet/v1/plans/show', status: :created, locals: { plan: new_version }
          else
            render_error(errors: [_('Plan not found or not eligible for versioning')], status: :not_found)
          end
        rescue ActiveRecord::RecordInvalid => e
          render_error(errors: [_("Failed to create version: #{e.message}")], status: :unprocessable_entity)
        end
      end
    end
  end
end
