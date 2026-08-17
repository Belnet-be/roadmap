# frozen_string_literal: true

class BelnetEditablePlanMetadata < ApplicationRecord
  self.table_name = 'belnet_editable_plan_metadata'

  belongs_to :plan
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  validate :lifecycle_stage_must_be_active, if: :lifecycle_stage_changed?

  private

  def lifecycle_stage_must_be_active
    return if lifecycle_stage.blank? || plan&.org.nil?
    return if plan.org.current_valid_belnet_stages.include?(lifecycle_stage)

    errors.add(:lifecycle_stage, 'is not an active lifecycle stage for this org')
  end
end
