# frozen_string_literal: true

class BelnetValidationsController < ApplicationController
  after_action :verify_authorized

  before_action :set_plan
  before_action :set_validation, only: :update

  # POST /plans/:plan_id/governance_validations
  # Creates a new validation request, is then reviewable.
  def create
    authorize @plan, :update?

    @validation = @plan.governance_validations.new(create_validation_params)
    @validation.requested_by = current_user
    validation_target = Plan.find_by(id: @validation.validated_plan_id) || @viewed_plan

    if @validation.save
      redirect_to validate_plan_path(validation_target), notice: success_message(@validation, _('requested'))
    else
      redirect_to validate_plan_path(validation_target), alert: failure_message(@validation, _('request'))
    end
  end

  # PUT /plans/:plan_id/governance_validations/:id
  def update
    authorize @plan, :review_validation?

    attrs = update_validation_params.merge(
      # Use actual timezone time, way better than time.now
      reviewed_by: current_user,
      reviewed_at: Time.zone.now
    )

    if @validation.update(attrs)
      redirect_to validate_plan_path(@viewed_plan), notice: success_message(@validation, _('reviewed'))
    else
      redirect_to validate_plan_path(@viewed_plan), alert: failure_message(@validation, _('review'))
    end
  end

  private

  # The validations tab can be opened from the LIVE plan or from one of its
  # versions, so :plan_id may be a version. Validations always belong to the
  # editable (LIVE) plan, which is the family head (belnet_family_id).
  def set_plan
    @viewed_plan = Plan.find(params[:plan_id])
    @plan = @viewed_plan.is_plan_live_version? ? @viewed_plan : Plan.find(@viewed_plan.belnet_family_id)
  end

  def set_validation
    @validation = @plan.governance_validations_for_org_topics.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to validate_plan_path(@viewed_plan), alert: _('Invalid topic validation review.')
  end

  # Strongparams only. Values are strings (name_ids);
  def create_validation_params
    params.require(:belnet_validation)
          .permit(:validation_topic, :validated_plan_id)
  end

  def update_validation_params
    params.require(:belnet_validation)
          .permit(:validation_status, :rationale, :conditions)
  end

  def validation_org
    @plan.org
  end

  def available_topics
    validation_org.active_validation_topics
  end

  def available_validation_statuses
    validation_org.active_validation_statuses
  end

  def available_validated_plans
    @plan.plan_versions
  end

  helper_method :available_topics, :available_validation_statuses, :available_validated_plans
end
