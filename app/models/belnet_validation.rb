# frozen_string_literal: true

class BelnetValidation < ApplicationRecord
  belongs_to :plan
  belongs_to :validated_plan, class_name: 'Plan'

  belongs_to :requested_by, class_name: 'User', optional: true
  belongs_to :reviewed_by, class_name: 'User', optional: true

  # Field presence
  validates :validation_topic, presence: true
  validates :validation_status, presence: true, if: -> { reviewed_at.present? }

  validate :validation_topic_must_be_active,  if: :validation_topic_changed?
  validate :validation_status_must_be_active, if: :validation_status_changed?

  validate :plan_must_be_editable_dmp
  validate :validated_plan_must_be_a_version

  validate :record_is_immutable_after_review, on: :update

  def requested_at
    # defined in doc
    created_at
  end

  private

  def validation_topic_must_be_active
    return if validation_topic.blank? || plan&.org.nil?
    return if plan.org.active_validation_topics.include?(validation_topic)

    errors.add(:validation_topic, 'is not an active validation topic for this org')
  end

  def validation_status_must_be_active
    return if validation_status.blank? || plan&.org.nil?
    return if plan.org.active_validation_statuses.include?(validation_status)

    errors.add(:validation_status, 'is not an active validation status for this org')
  end

  def plan_must_be_editable_dmp
    return if plan.nil?
    return if plan.is_plan_live_version?

    errors.add(:plan, 'must reference the editable (live) DMP')
  end

  def validated_plan_must_be_a_version
    return if validated_plan.nil?
    return if validated_plan.belnet_version.to_i.positive?

    errors.add(:validated_plan, 'must reference a version snapshot')
  end

  def record_is_immutable_after_review
    return unless reviewed_at_was.present?

    errors.add(:base, 'This validation has already been reviewed')
  end
end
