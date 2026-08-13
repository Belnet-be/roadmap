# frozen_string_literal: true

class BelnetValidation < ApplicationRecord
  belongs_to :plan
  belongs_to :validated_plan, class_name: 'Plan'

  belongs_to :requested_by, class_name: 'User', optional: true
  belongs_to :reviewed_by, class_name: 'User', optional: true

  # Validations
  validates :validation_topic, presence: true
  validates :validation_status, presence: true, if: -> { reviewed_at.present? }

  def requested_at
    # defined in doc
    created_at
  end
end
