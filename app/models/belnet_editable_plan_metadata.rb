# frozen_string_literal: true

class BelnetEditablePlanMetadata < ApplicationRecord
  self.table_name = 'belnet_editable_plan_metadata'

  belongs_to :plan
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
end
