# frozen_string_literal: true

# Per-org (or global when org_id is nil) configuration listing the lifecycle
# stage names that plans in the org can move through. Stage names live inside
# JSON arrays:
# - current_list_order: active names shown in dropdowns/ picked as default
# - full_list_order   : superset including deprecated names, so historical
#                         references resolves during audits
class BelnetConfigLifecycleStage < ApplicationRecord
  self.table_name = 'belnet_config_lifecycle_stages'

  belongs_to :org, optional: true

  attribute :current_list_order, default: -> { [] }
  attribute :full_list_order,    default: -> { [] }

  def self.for_org(org)
    find_by(org_id: org&.id) || find_by(org_id: nil)
  end
end
