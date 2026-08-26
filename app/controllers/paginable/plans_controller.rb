# frozen_string_literal: true

module Paginable
  # Controller for paginating/sorting/searching the plans tables
  class PlansController < ApplicationController
    include Paginable
    include PlanDashboardFilters

    # /paginable/plans/privately_visible/:page
    def privately_visible
      authorize Plan

      filters = plan_dashboard_filter_params

      paginable_renderise(
        partial: 'privately_visible',
        scope: apply_plan_dashboard_filters(Plan.includes(:roles).active(current_user), filters),
        query_params: { sort_field: 'plans.updated_at', sort_direction: :desc }.merge(filters.compact),
        format: :json
      )
    end

    def history
      @plan = Plan.find(params[:id])
      authorize @plan

      scope = @plan.plan_versions
                   .includes(:belnet_version_metadata,
                             belnet_stage_histories: :user)

      paginable_renderise(
        partial: 'history',
        scope: scope,
        locals: { plan: @plan },
        query_params: { sort_field: 'plans.updated_at', sort_direction: :desc },
        format: :json
      )
    end

    # /paginable/plans/:id/validate/:page
    # AJAX pagination for the validations tab on the plan detail page. Loads the shared
    # "available topics/statuses/versions" the render partial needs so the section
    # renders identically on the initial page and on paginated fetches
    def validate
      @plan = Plan.find(params[:id])
      authorize @plan

      scope = @plan.governance_validations
                   .includes(:requested_by, :reviewed_by, :validated_plan)
                   .order(created_at: :desc)

      paginable_renderise(
        partial: 'validate',
        scope: scope,
        locals: {
          plan: @plan,
          available_topics: @plan.org.active_validation_topics,
          available_validation_statuses: @plan.org.active_validation_statuses,
          available_validated_plans: @plan.plan_versions.order(belnet_version: :desc)
        },
        query_params: { id: @plan.id },
        format: :json
      )
    end

    # GET /paginable/plans/organisationally_or_publicly_visible/:page
    def organisationally_or_publicly_visible
      authorize Plan

      paginable_renderise(
        partial: 'organisationally_or_publicly_visible',
        scope: Plan.organisationally_or_publicly_visible(current_user),
        query_params: { sort_field: 'plans.updated_at', sort_direction: :desc },
        format: :json
      )
    end

    # GET /paginable/plans/publicly_visible/:page
    def publicly_visible
      # We want the pagination/sort/search to be retained in the URL so redirect instead
      # of processing this as a JSON
      paginable_params = params.permit(:page, :search, :sort_field, :sort_direction)
      redirect_to public_plans_path(paginable_params.to_h)
    end

    # GET /paginable/plans/org_admin/:page
    # rubocop:disable Metrics/AbcSize
    def org_admin
      raise Pundit::NotAuthorizedError unless current_user.present? && current_user.can_org_admin?

      # check if current user if super_admin
      @super_admin = current_user.can_super_admin?
      @clicked_through = params[:click_through].present?
      plans = @super_admin ? Plan.all : current_user.org.org_admin_plans
      plans = plans.joins(:template, roles: [user: :org]).where(Role.creator_condition)

      filters = plan_dashboard_filter_params

      paginable_renderise(
        partial: 'org_admin',
        scope: apply_plan_dashboard_filters(plans, filters, reviewable_check: false),
        view_all: !current_user.can_super_admin?,
        query_params: { sort_field: 'plans.updated_at', sort_direction: :desc }.merge(filters.compact),
        format: :json
      )
    end
    # rubocop:enable Metrics/AbcSize

    # GET /paginable/users/:id/plans
    def index
      @user = User.find(params[:id])
      authorize @user
      raise Pundit::NotAuthorizedError unless current_user.present? && current_user.can_org_admin? && @user.present?

      paginable_renderise(
        partial: 'index',
        scope: Plan.active(@user),
        query_params: { sort_field: 'plans.updated_at', sort_direction: :desc },
        format: :json
      )
    end
  end
end
