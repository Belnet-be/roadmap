# frozen_string_literal: true

class BelnetValidationsController < ApplicationController
  after_action :verify_authorized

  before_action :set_plan
  before_action :set_validation, only: :update

  # POST /plans/:plan_id/governance_validations
  # Will create a new validation request for a version, reviewer (currently anyone) can review the
  # plan based on the orgs statuses
  # inititally status is nil and reviewer then sets it to one of available
  # statuses, and can add rationale and conditions if applicable
  def create
    authorize @plan, :update?

    @validation = @plan.governance_validations.new(create_validation_params)
    @validation.requested_by = current_user

    if @validation.save
      redirect_to share_plan_path(@plan), notice: success_message(@validation, _('requested'))
    else
      redirect_to share_plan_path(@plan), alert: failure_message(@validation, _('request'))
    end
  rescue ActionController::BadRequest => e
    # bad request, throw error in flash and redirect to plan page (share tab)
    redirect_to share_plan_path(@plan), alert: e.message
  end

  # PUT /plans/:plan_id/governance_validations/:id
  # Will update the status of a validation request, and add rationale and conditions if applicable
  def update
    authorize @plan, :update?

    unless reviewable?(@validation)
      return redirect_to share_plan_path(@plan), alert: _('This governance validation can no longer be reviewed.')
    end

    attrs = update_validation_params.merge(
      # Use actual timezone time, way better than time.now
      reviewed_by: current_user,
      reviewed_at: Time.zone.now
    )

    if @validation.update(attrs)
      redirect_to share_plan_path(@plan), notice: success_message(@validation, _('reviewed'))
    else
      redirect_to share_plan_path(@plan), alert: failure_message(@validation, _('review'))
    end
  rescue ActionController::BadRequest => e
    redirect_to share_plan_path(@plan), alert: e.message
  end

  private

  def set_plan
    @plan = Plan.find(params[:plan_id])
  end

  def set_validation
    @validation = @plan.governance_validations_for_org_topics.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ActionController::BadRequest, _('Invalid governance validation review.')
  end

  # Form submits :validation_topic (a name string) and :validated_plan_id
  def create_validation_params
    raw = params.require(:belnet_validation)
                .permit(:validation_topic, :validated_plan_id)

    unless available_topics.include?(raw[:validation_topic].to_s)
      raise ActionController::BadRequest, _('Invalid governance validation request.')
    end

    validated_plan = available_validated_plans.find(raw[:validated_plan_id])

    {
      validation_topic: raw[:validation_topic].to_s,
      validated_plan_id: validated_plan.id
    }
  rescue ActiveRecord::RecordNotFound
    raise ActionController::BadRequest, _('Invalid governance validation request.')
  end

  def update_validation_params
    raw = params.require(:belnet_validation)
                .permit(:validation_status, :rationale, :conditions)

    unless available_validation_statuses.include?(raw[:validation_status].to_s)
      raise ActionController::BadRequest, _('Invalid governance validation review.')
    end

    {
      validation_status: raw[:validation_status].to_s,
      rationale: raw[:rationale],
      conditions: raw[:conditions]
    }
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

  def reviewable?(validation)
    validation.reviewed_at.blank?
  end
end
