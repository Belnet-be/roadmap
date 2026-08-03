# frozen_string_literal: true

class BelnetStage < ApplicationRecord
  belongs_to :org, optional: true
  has_many :belnet_editable_plan_metadata,
           class_name: 'BelnetEditablePlanMetadata',
           dependent: :nullify
  has_many :belnet_stage_histories, dependent: :destroy

  # This still allows for an org stage to share a name with a global stage
  validates :name_id, presence: true, uniqueness: { scope: :org_id }
end
