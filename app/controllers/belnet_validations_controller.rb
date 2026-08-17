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

    if @validation.save
      redirect_to share_plan_path(@plan), notice: success_message(@validation, _('requested'))
    else
      redirect_to share_plan_path(@plan), alert: failure_message(@validation, _('request'))
    end
  end

  # PUT /plans/:plan_id/governance_validations/:id
  def update
    authorize @plan, :update?

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
  end

  private

  def set_plan
    @plan = Plan.find(params[:plan_id])
  end

  def set_validation
    @validation = @plan.governance_validations_for_org_topics.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to share_plan_path(@plan), alert: _('Invalid governance validation review.')
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
