# frozen_string_literal: true

module Api
  module Belnet
    module V1
      # Handles CRUD operations for versions in API V1 for Belnet
      class VersionsController < BaseApiController
        respond_to :json

        # GET /api/belnet-v1/plans/:plan_id/versions
        def index
          # This endpoint should return a collection of plans that are associated to the given plan
          # by their family_id (column: belnet_family_id).
          plan = find_editable_plan
          return if performed?

          versions = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan)
                                                        .resolve
                                                        .where(belnet_family_id: plan.id)
                                                        .where('belnet_version > ?', 0)
                                                        .includes(:belnet_version_metadata)
                                                        .order(belnet_version: :desc)

          @items = paginate_response(results: versions)
          render 'api/belnet/v1/versions/index', status: :ok
        end

        # GET /api/belnet-v1/plans/:plan_id/versions/:id
        # :id is the version_number (belnet_version), not the plan_id of the
        # version snapshot.
        def show
          if params[:id].blank? || params[:id].to_i <= 0
            render_error(errors: [_('Invalid version number')], status: :bad_request)
            return
          end

          plan = find_editable_plan
          return if performed?

          version = plan.plan_versions
                        .includes(:belnet_version_metadata)
                        .find_by(belnet_version: params[:id])

          unless version
            render_error(errors: [_('Version not found')], status: :not_found)
            return
          end

          render 'api/belnet/v1/versions/show', status: :ok, locals: { version: version }
        end

        # PUT /api/belnet-v1/plans/:plan_id/versions/:id
        # :id is the version_number. Updates the reason and/or lifecycle_stage
        # of an existing version version, both fields are optional
        # but atleast one is required
        def update
          if params[:id].blank? || params[:id].to_i <= 0
            render_error(errors: [_('Invalid version number')], status: :bad_request)
            return
          end

          plan = find_editable_plan
          return if performed?

          version = plan.plan_versions
                        .includes(:belnet_version_metadata)
                        .find_by(belnet_version: params[:id])

          unless version
            render_error(errors: [_('Version not found')], status: :not_found)
            return
          end

          new_reason = params[:reason]
          new_stage  = resolve_stage_for(version)
          return if performed?

          if new_reason.nil? && new_stage.nil?
            render_error(errors: [_('At least one of the parameters reason or lifecycle_stage is required')],
                         status: :bad_request)
            return
          end

          acting_user = client.is_a?(User) ? client : nil

          version.transaction do
            if new_reason
              metadata = version.belnet_version_metadata || version.touch_version_metadata!(acting_user)
              metadata.reason = new_reason
              metadata.updated_by = acting_user
              metadata.updated_at = Time.current
              metadata.save!(context: :versioning)
            end
            version.update_stage(new_stage, acting_user) if new_stage
          end

          version.reload
          render 'api/belnet/v1/versions/show', status: :accepted, locals: { version: version }
        rescue ActiveRecord::RecordInvalid => e
          render_error(errors: e.record.errors.full_messages, status: :bad_request)
        end

        # POST /api/belnet-v1/plans/:plan_id/versions
        def create
          # This endpoint should create a new version of a plan given that the plan in question's belnet_version
          # is 0 (This means it's the LIVE version).
          plan = find_editable_plan
          return if performed?

          stage = resolve_version_stage(plan)
          return if performed?

          # User retrieval (better than current_user), client could be API client
          acting_user = client.is_a?(User) ? client : nil
          new_version = plan.create_plan_with_new_version!(
            reason: @json&.[]('reason'),
            current_user: acting_user,
            original_plan: plan,
            new_stage: stage
          )

          render 'api/belnet/v1/versions/create', status: :created,
                                                  locals: { version: new_version,
                                                            created_by_user: acting_user }
        rescue ActiveRecord::RecordInvalid => e
          render_error(errors: e.record.errors.full_messages, status: :bad_request)
        end

        private

        # Loads the editable (LIVE) DMP for the request. Renders an error and
        # returns nil when the plan is missing or not the live version.
        def find_editable_plan
          plan = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
                                                    .where(id: params[:plan_id])
                                                    .first

          unless plan
            render_error(errors: [_('Plan not found')], status: :not_found)
            return nil
          end

          unless plan.is_plan_live_version?
            render_error(errors: [_('Versions can only be created from an editable DMP')],
                         status: :bad_request)
            return nil
          end

          plan
        end

        def resolve_stage_for(_plan)
          stage_name = params[:lifecycle_stage].to_s.strip
          stage_name.presence
        end

        # lifecycle_stage is optional. When omitted, fall back to the most
        # recent versions stage, then to the live plan's current stage.
        def resolve_version_stage(plan)
          stage_name = params[:lifecycle_stage]
          return stage_name if stage_name.present?

          plan.plan_versions.order(:belnet_version).last&.current_lifecycle_stage_name ||
            plan.current_lifecycle_stage_name
        end
      end
    end
  end
end
