class BelnetValidation < ApplicationRecord
  belongs_to :plan
  belongs_to :validated_plan, class_name: 'Plan'
  belongs_to :belnet_validation_topic
  belongs_to :belnet_validation_status
  belongs_to :requested_by, class_name: 'User', optional: true
  belongs_to :decided_by, class_name: 'User', optional: true

  def requested_at
    # defined in doc
    created_at
  end
end
