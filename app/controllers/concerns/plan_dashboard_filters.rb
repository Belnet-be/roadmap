# frozen_string_literal: true

module PlanDashboardFilters
  extend ActiveSupport::Concern

  # Constants
  FILTER_KEYS = %i[stage exclude_test_plans include_versions].freeze

  TRUTHY_FILTER_VALUES = %w[1 true on yes].to_set.freeze

  private

  # returns a hash of the filter params that are present in the request
  def plan_dashboard_filter_params
    params.permit(*FILTER_KEYS).to_h.symbolize_keys
  end

  # applies the filters to the given scope based on the provided filter params
  def apply_plan_dashboard_filters(scope, filters = plan_dashboard_filter_params)
    scope = scope.live_versions unless dashboard_filter_truthy?(filters[:include_versions])
    scope = scope.with_lifecycle_stage(filters[:stage]) if filters[:stage].present?
    scope = scope.excluding_test_plans if dashboard_filter_truthy?(filters[:exclude_test_plans])
    scope.grouped_by_family
  end

  # returns true if the given value is considered truthy for the purpose of filtering
  def dashboard_filter_truthy?(value)
    TRUTHY_FILTER_VALUES.include?(value.to_s.downcase)
  end
end
