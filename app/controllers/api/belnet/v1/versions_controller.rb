# frozen_string_literal: true

module Api
  module Belnet
    module V1
      # Handles CRUD operations for versions in API V1 for Belnet
      class VersionsController < BaseApiController
        respond_to :json

        # GET /api/belnet-v1/plans/:plan_id/versions
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

        # GET /api/belnet-v1/plans/:plan_id/versions/:id (:id means version number in this case)
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
                render 'api/belnet/v1/plans/versions/show', status: :ok, locals: { plan: version }
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

        # POST /api/belnet-v1/plans/:plan_id/versions
        def create
          # This endpoint should create a new version of a plan given that the plan in question's belnet_version
          # is 0 (This means it's the LIVE version).
          plan = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
                                                    .where(id: params[:plan_id])
                                                    .first

          unless plan
            render_error(errors: [_('Plan not found')], status: :not_found)
            return
          end

          unless plan.is_plan_live_version?
            render_error(errors: [_('Versions can only be created from an editable DMP')],
                         status: :bad_request)
            return
          end

          stage = resolve_version_stage(plan)
          return if performed?

          # User retrievel (better than current_user), client could be API client
          acting_user = client.is_a?(User) ? client : nil
          new_version = plan.create_plan_with_new_version!(
            reason: params[:reason],
            current_user: acting_user,
            original_plan: plan,
            new_stage: stage
          )

          render 'api/belnet/v1/versions/create', status: :created,
                                                  locals: { version: new_version,
                                                            created_by_user: acting_user }
        rescue ActiveRecord::RecordInvalid => e
          render_error(errors: [_("Failed to create version: #{e.message}")], status: :bad_request)
        end

        private

        # lifecyclestage is optional. When omitted, use the last versions stage
        # (or the live plan's stage), this way it is possible to create a new version without needing to pass the stage.
        def resolve_version_stage(plan)
          stage_name = @json&.[]('lifecycle-stage').to_s.strip

          if stage_name.present?
            stage = plan.org&.current_valid_belnet_stages&.find { |s| s.name_id == stage_name }
            unless stage
              render_error(errors: [_('Lifecycle stage not found')], status: :bad_request)
              return nil
            end
            return stage
          end

          plan.plan_versions.order(:belnet_version).last&.current_belnet_stage ||
            plan.current_belnet_stage
        end
      end
    end
  end
end
