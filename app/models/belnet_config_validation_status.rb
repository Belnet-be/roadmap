# frozen_string_literal: true

# Per org (or global when org_id is nil) configuration listing the validation
# status names.
class BelnetConfigValidationStatus < ApplicationRecord
  self.table_name = 'belnet_config_validation_statuses'

  belongs_to :org, optional: true

  attribute :current_list_order, default: -> { [] }
  attribute :full_list_order,    default: -> { [] }

  def self.for_org(org)
    find_by(org_id: org&.id) || find_by(org_id: nil)
  end
end
