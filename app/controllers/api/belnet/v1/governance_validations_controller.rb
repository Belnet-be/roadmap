# frozen_string_literal: true

module Api
  module Belnet
    module V1
      # Handles CRUD operations for governance validations in API V1 for Belnet.
      # Exposed publicly under /api/belnet-v1/plans/:plan_id/validations.
      class GovernanceValidationsController < BaseApiController
        respond_to :json

        # GET /api/belnet-v1/plans/:plan_id/validations
        def index
          plan = find_editable_plan
          return if performed?

          validations = plan.governance_validations
                            .includes(:validated_plan,
                                      { requested_by: :identifiers },
                                      { reviewed_by: :identifiers })
                            .order(created_at: :desc)

          @items = paginate_response(results: validations)
          render 'api/belnet/v1/validations/index', status: :ok
        end

        # GET /api/belnet-v1/plans/:plan_id/validations/:id
        def show
          plan = find_editable_plan
          return if performed?

          validation = find_validation(plan)
          return unless validation

          render 'api/belnet/v1/validations/show', status: :ok,
                                                   locals: { validation: validation }
        end

        # PUT /api/belnet-v1/plans/:plan_id/validations/:id
        # One-shot review: once reviewed_at is set, further edits are rejected.
        def update
          plan = find_editable_plan
          return if performed?

          validation = find_validation(plan)
          return unless validation

          if validation.reviewed_at.present?
            render_error(errors: [_('This validation has already been reviewed')],
                         status: :bad_request)
            return
          end

          status_name = resolve_status(plan)
          return if performed?

          acting_user = client.is_a?(User) ? client : nil

          validation.assign_attributes(
            validation_status: status_name,
            rationale: params[:rationale],
            conditions: params[:conditions],
            reviewed_by: acting_user,
            reviewed_at: Time.zone.now
          )
          validation.save!

          render 'api/belnet/v1/validations/show', status: :accepted,
                                                   locals: { validation: validation }
        rescue ActiveRecord::RecordInvalid => e
          render_error(errors: e.record.errors.full_messages, status: :bad_request)
        end

        # POST /api/belnet-v1/plans/:plan_id/validations
        # Body: { "dmp_version_number": <int>, "topic": "<name>" }
        def create
          plan = find_editable_plan
          return if performed?

          version = resolve_version(plan)
          return if performed?

          topic_name = resolve_topic(plan)
          return if performed?

          acting_user = client.is_a?(User) ? client : nil

          validation = plan.governance_validations.new(
            validated_plan: version,
            validation_topic: topic_name,
            requested_by: acting_user
          )
          validation.save!

          render 'api/belnet/v1/validations/create', status: :created,
                                                     locals: { validation: validation }
        rescue ActiveRecord::RecordInvalid => e
          render_error(errors: e.record.errors.full_messages, status: :bad_request)
        end

        private

        # Loads the editable (LIVE) DMP for the request.
        def find_editable_plan
          plan = Api::Belnet::V1::PlansPolicy::Scope.new(client, Plan).resolve
                                                    .where(id: params[:plan_id])
                                                    .first

          unless plan
            render_error(errors: [_('Plan not found')], status: :not_found)
            return nil
          end

          unless plan.is_plan_live_version?
            render_error(errors: [_('plan_id must reference the editable (live) DMP')],
                         status: :bad_request)
            return nil
          end

          plan
        end

        def find_validation(plan)
          validation = plan.governance_validations
                           .includes(:validated_plan,
                                     { requested_by: :identifiers },
                                     { reviewed_by: :identifiers })
                           .find_by(id: params[:id])

          return validation if validation

          render_error(errors: [_('Validation not found')], status: :not_found)
          nil
        end

        def resolve_status(plan)
          status_name = params[:status]

          if status_name.blank?
            render_error(errors: [_('status is required')], status: :bad_request)
            return nil
          end

          return status_name if plan.org&.active_validation_statuses&.include?(status_name)

          render_error(errors: [_('Validation status not found')], status: :bad_request)
          nil
        end

        def resolve_version(plan)
          version_number = params[:dmp_version_number]

          if version_number.blank? || version_number.to_i <= 0
            render_error(errors: [_('dmp_version_number is required')], status: :bad_request)
            return nil
          end

          version = plan.plan_versions.find_by(belnet_version: version_number.to_i)
          return version if version

          render_error(errors: [_('DMP version not found')], status: :bad_request)
          nil
        end

        def resolve_topic(plan)
          topic_name = params[:topic]

          if topic_name.blank?
            render_error(errors: [_('topic is required')], status: :bad_request)
            return nil
          end

          return topic_name if plan.org&.active_validation_topics&.include?(topic_name)

          render_error(errors: [_('Validation topic not found')], status: :bad_request)
          nil
        end
      end
    end
  end
end
