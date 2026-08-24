# frozen_string_literal: true

module PlanDashboardFilters
  extend ActiveSupport::Concern

  # Constants
  FILTER_KEYS = %i[title template_id stage exclude_test_plans include_versions
                   validation_topic validation_status time_period
                   min_completion_rate pending_my_review].freeze

  TRUTHY_FILTER_VALUES = %w[1 true on yes].to_set.freeze

  # Options for minimum completion rate filter
  COMPLETION_RATE_OPTIONS = {
    '25' => 'At least 25%',
    '50' => 'At least 50%',
    '75' => 'At least 75%',
    '100' => '100%'
  }.freeze

  # Options for time period filter
  TIME_PERIOD_OPTIONS = {
    '1d' => { label: 'Today',          window: 1.day },
    '7d' => { label: 'Last 7 days',    window: 7.days },
    '30d' => { label: 'Last 30 days', window: 30.days },
    '3m' => { label: 'Last 3 months',  window: 3.months },
    '6m' => { label: 'Last 6 months',  window: 6.months },
    '12m' => { label: 'Last 12 months', window: 12.months },
    '2y' => { label: 'Last 2 years', window: 2.years }
  }.freeze

  private

  # returns a hash of the filter params that are present in the request
  def plan_dashboard_filter_params
    params.permit(*FILTER_KEYS).to_h.symbolize_keys
  end

  # Applies the filters to the given scope based on the provided filter params
  def apply_plan_dashboard_filters(scope, filters = plan_dashboard_filter_params,
                                   reviewable_check: default_reviewable_check)
    scope = scope.live_versions unless dashboard_filter_truthy?(filters[:include_versions])
    scope = scope.titled_like(filters[:title]) if filters[:title].present?
    scope = scope.using_template(filters[:template_id]) if filters[:template_id].present?
    scope = scope.with_lifecycle_stage(filters[:stage]) if filters[:stage].present?
    scope = scope.excluding_test_plans if dashboard_filter_truthy?(filters[:exclude_test_plans])
    scope = scope.with_validation_topic(filters[:validation_topic]) if filters[:validation_topic].present?
    scope = scope.with_validation_status(filters[:validation_status]) if filters[:validation_status].present?
    if (window = time_period_window(filters[:time_period]))
      scope = scope.active_since(window.ago)
    end
    if dashboard_filter_truthy?(filters[:pending_my_review])
      scope = scope.with_pending_validation
      if reviewable_check
        reviewable_ids = scope.to_a.select { |plan| reviewable_check.call(plan) }.map(&:id)
        scope = scope.where(id: reviewable_ids)
      end
    end
    scope = scope.with_completion_at_least(filters[:min_completion_rate]) if filters[:min_completion_rate].present?
    scope.grouped_by_family
  end

  # returns true if the given value is considered truthy for the purpose of filtering
  def dashboard_filter_truthy?(value)
    TRUTHY_FILTER_VALUES.include?(value.to_s.downcase)
  end

  def time_period_window(key)
    TIME_PERIOD_OPTIONS.dig(key, :window)
  end

  def default_reviewable_check
    user_id = current_user&.id
    return nil unless user_id

    ->(plan) { plan.editable_by?(user_id) }
  end
end
