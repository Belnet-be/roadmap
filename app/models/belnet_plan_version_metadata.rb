# frozen_string_literal: true

class BelnetPlanVersionMetadata < ApplicationRecord
  self.table_name = 'belnet_plan_version_metadata'

  belongs_to :plan
  belongs_to :editable_plan, class_name: 'Plan', optional: true
  belongs_to :versioned_plan, class_name: 'Plan', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  # Snapshotted stage name (name_id). Kept alongside for durability if the
  # backing BelnetStage is renamed or removed.
end
