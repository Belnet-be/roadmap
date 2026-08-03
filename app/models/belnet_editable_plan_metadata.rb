# frozen_string_literal: true

class BelnetEditablePlanMetadata < ApplicationRecord
  self.table_name = 'belnet_editable_plan_metadata'

  belongs_to :plan
  belongs_to :belnet_stage, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  before_save :sync_lifecycle_stage

  private

  def sync_lifecycle_stage
    self.lifecycle_stage = belnet_stage&.name_id if belnet_stage_id_changed?
  end
end
