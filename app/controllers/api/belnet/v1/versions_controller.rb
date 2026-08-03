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
        # :id is the version_number. Updates the reason and/or lifecycle-stage
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
            render_error(errors: [_('At least one of reason or lifecycle-stage is required')],
                         status: :bad_request)
            return
          end

          acting_user = client.is_a?(User) ? client : nil

          version.transaction do
            if new_reason
              version.assign_attributes(belnet_reason: new_reason)
              version.save!(context: :versioning)
            end
            version.update_stage_by_name(new_stage.name_id, acting_user) if new_stage
            version.touch_version_metadata!(acting_user) if new_reason && new_stage.nil?
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

        def resolve_stage_for(plan)
          stage_name = params[:'lifecycle-stage']
          return nil if stage_name.blank?

          stage = plan.org&.current_valid_belnet_stages&.find { |s| s.name_id == stage_name }
          return stage if stage

          render_error(errors: [_('Lifecycle stage not found')], status: :bad_request)
          nil
        end

        # lifecycle stage is optional, if omitted, fall back to previous versions stage
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
