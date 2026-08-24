# frozen_string_literal: true

# The central model object within this domain. Represents a Data Management
# Plan for a research project.
#
# == Schema Information
#
# Table name: plans
#
#  id                                :integer          not null, primary key
#  complete                          :boolean          default(FALSE)
#  description                       :text
#  feedback_requested                :boolean          default(FALSE)
#  identifier                        :string
#  title                             :string
#  visibility                        :integer          default(3), not null
#  created_at                        :datetime
#  updated_at                        :datetime
#  template_id                       :integer
#  org_id                            :integer
#  funder_id                         :integer
#  grant_id                          :integer
#  api_client_id                     :integer
#  research_domain_id                :bigint
#  funding_status                    :integer
#  ethical_issues                    :boolean
#  ethical_issues_description        :text
#  ethical_issues_report             :string
#
# Indexes
#
#  index_plans_on_template_id   (template_id)
#  index_plans_on_funder_id     (funder_id)
#  index_plans_on_grant_id      (grant_id)
#  index_plans_on_api_client_id (api_client_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_id => templates.id)
#  fk_rails_...  (org_id => orgs.id)
#  fk_rails_...  (api_client_id => api_clients.id)
#  fk_rails_...  (research_domain_id => research_domains.id)
#

# Object that represents an DMP
# rubocop:disable Metrics/ClassLength
class Plan < ApplicationRecord
  include ConditionalUserMailer
  include ExportablePlan
  include DateRangeable
  include Identifiable

  # =============
  # = Constants =
  # =============

  DMP_ID_TYPES = %w[ark doi].freeze

  # Returns visibility message given a Symbol type visibility passed, otherwise
  # nil
  VISIBILITY_MESSAGE = {
    organisationally_visible: _('organisational'),
    publicly_visible: _('public'),
    is_test: _('test'),
    privately_visible: _('private')
  }.freeze

  FUNDING_STATUS = {
    planned: _('Planned'),
    funded: _('Funded'),
    denied: _('Denied')
  }.freeze

  # ==============
  # = Attributes =
  # ==============

  # public is a Ruby keyword so using publicly
  enum visibility: %i[organisationally_visible publicly_visible
                      is_test privately_visible]

  enum funding_status: %i[planned funded denied]

  alias_attribute :name, :title

  # ================
  # = Associations =
  # ================

  belongs_to :template

  belongs_to :org

  belongs_to :funder, class_name: 'Org', optional: true

  belongs_to :api_client, optional: true

  belongs_to :research_domain, optional: true

  has_many :phases, through: :template

  has_many :sections, through: :phases

  has_many :questions, through: :sections

  has_many :themes, through: :questions

  has_many :guidances, through: :themes

  has_many :guidance_group_options, -> { distinct.includes(:org).published.reorder('id') },
           through: :guidances,
           source: :guidance_group,
           class_name: 'GuidanceGroup'

  has_many :answers, dependent: :destroy

  has_many :notes, through: :answers

  has_many :roles, dependent: :destroy

  has_many :users, through: :roles

  has_and_belongs_to_many :guidance_groups, join_table: :plans_guidance_groups

  has_many :exported_plans, dependent: :destroy

  has_many :contributors, dependent: :destroy

  has_one :grant, as: :identifiable, dependent: :destroy, class_name: 'Identifier'

  has_many :research_outputs, dependent: :destroy

  has_many :belnet_stage_histories, -> { order(created_at: :desc) }, dependent: :destroy

  # Lookup table holding extra metadata for editable/live plans (belnet_version = 0)
  # Only present on editable plans; nil on versions
  has_one :belnet_editable_plan_metadata,
          class_name: 'BelnetEditablePlanMetadata',
          dependent: :destroy

  # Connects metadata to plans using two foreign keys:
  # - versioned_plan_id: points to the specific version (one to one)
  # - editable_plan_id : points to the parent plan this version came from (one to many)
  # #belnet_version_metadata when reading a versions own metadata
  # #belnet_plan_version_metadata on the parent to clean up metadata on delete
  has_one :belnet_version_metadata,
          class_name: 'BelnetPlanVersionMetadata',
          foreign_key: :versioned_plan_id,
          dependent: :destroy

  has_many :belnet_plan_version_metadata,
           class_name: 'BelnetPlanVersionMetadata',
           foreign_key: :editable_plan_id,
           dependent: :destroy

  has_many :governance_validations, class_name: 'BelnetValidation', foreign_key: :plan_id

  has_many :version_validations, class_name: 'BelnetValidation', foreign_key: :validated_plan_id

  # =====================
  # = Nested Attributes =
  # =====================

  accepts_nested_attributes_for :template

  accepts_nested_attributes_for :roles

  accepts_nested_attributes_for :contributors

  # ===============
  # = Validations =
  # ===============

  validates :title, presence: { message: PRESENCE_MESSAGE }

  validates :template, presence: { message: PRESENCE_MESSAGE }

  validates :feedback_requested, inclusion: { in: BOOLEAN_VALUES }

  validates :complete, inclusion: { in: BOOLEAN_VALUES }

  validates :belnet_version, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :belnet_version, presence: { message: PRESENCE_MESSAGE }

  validates :belnet_family_id, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  validate :end_date_after_start_date

  # ==========
  # = Scopes =
  # ==========

  # Retrieves any plan in which the user has an active role and
  # is not a reviewer
  scope :active, lambda { |user|
    plan_ids = Role.where(active: true, user_id: user.id).pluck(:plan_id)

    includes(:template, :roles)
      .where(id: plan_ids)
  }

  # Retrieves any plan organisationally or publicly visible for a given org id
  scope :organisationally_or_publicly_visible, lambda { |user|
    plan_ids = user.org.org_admin_plans.where(complete: true).pluck(:id).uniq
    includes(:template, roles: :user)
      .where(id: plan_ids, visibility: [
               visibilities[:organisationally_visible],
               visibilities[:publicly_visible]
             ])
      .where(
        'NOT EXISTS (SELECT 1 FROM roles WHERE plan_id = plans.id AND user_id = ?)',
        user.id
      )
  }

  scope :search, lambda { |term|
    if date_range?(term: term)
      joins(:template, roles: [user: :org])
        .where(roles: { active: true })
        .by_date_range(:created_at, term)
    else
      search_pattern = "%#{term}%"
      joins(:template, roles: [user: :org])
        .left_outer_joins(:identifiers, :contributors)
        .where(roles: { active: true })
        .where("lower(plans.title) LIKE lower(:search_pattern)
                OR lower(orgs.name) LIKE lower (:search_pattern)
                OR lower(orgs.abbreviation) LIKE lower (:search_pattern)
                OR lower(templates.title) LIKE lower(:search_pattern)
                OR lower(contributors.name) LIKE lower(:search_pattern)
                OR lower(identifiers.value) LIKE lower(:search_pattern)",
               search_pattern: search_pattern)
    end
  }

  ##
  # Defines the filter_logic used in the statistics objects.
  # For now, we filter out any test plans
  scope :stats_filter, -> { where.not(visibility: visibilities[:is_test]) }

  # Retrieves plan, template, org, phases, sections and questions
  scope :overview, lambda { |id|
    includes(:phases, :sections, :questions, template: [:org]).find(id)
  }

  scope :live_versions, -> { where(belnet_version: 0) }

  scope :with_lifecycle_stage, lambda { |stage_name|
    next all if stage_name.blank?

    left_joins(:belnet_editable_plan_metadata, :belnet_version_metadata)
      .where(
        'belnet_editable_plan_metadata.lifecycle_stage = :stage ' \
        'OR belnet_plan_version_metadata.lifecycle_stage = :stage',
        stage: stage_name
      )
  }

  scope :with_validation_topic, lambda { |topic|
    next all if topic.blank?

    joins(:belnet_validations)
      .where(belnet_validations: { topic: topic })
  }

  scope :excluding_test_plans, -> { where.not(visibility: visibilities[:is_test]) }

  # Case insensitive substring match on the plan title
  scope :titled_like, lambda { |term|
    next all if term.to_s.strip.blank?

    pattern = "%#{term.to_s.strip.downcase}%"
    where('LOWER(plans.title) LIKE ?', pattern)
  }

  # Filter by template id
  scope :using_template, lambda { |template_id|
    next all if template_id.blank?

    where(template_id: template_id)
  }

  # Filter by validation topic name. A plan matches when it appears on any
  # BelnetValidation for the given topic
  scope :with_validation_topic, lambda { |topic_name|
    next all if topic_name.blank?

    where(
      'plans.id IN (SELECT plan_id FROM belnet_validations WHERE validation_topic = :t) ' \
      'OR plans.id IN (SELECT validated_plan_id FROM belnet_validations WHERE validation_topic = :t)',
      t: topic_name
    )
  }

  # Same pattern as with_validation_topic but keyed on validation_status
  scope :with_validation_status, lambda { |status_name|
    next all if status_name.blank?

    where(
      'plans.id IN (SELECT plan_id FROM belnet_validations WHERE validation_status = :s) ' \
      'OR plans.id IN (SELECT validated_plan_id FROM belnet_validations WHERE validation_status = :s)',
      s: status_name
    )
  }

  # Plans created OR modified since the given time
  scope :active_since, lambda { |threshold|
    next all if threshold.nil?

    where('plans.created_at >= :t OR plans.updated_at >= :t', t: threshold)
  }

  # Restricts to plans that have at least one pending validation (reviewed_at IS NULL)
  scope :with_pending_validation, lambda {
    where(
      'plans.id IN (SELECT plan_id FROM belnet_validations WHERE reviewed_at IS NULL) ' \
      'OR plans.id IN (SELECT validated_plan_id FROM belnet_validations WHERE reviewed_at IS NULL)'
    )
  }

  # Restricts to plans whose #percent_answered is greater than or equal to the given threshold
  # The threshold is expected to be a string
  scope :with_completion_at_least, lambda { |percent_threshold|
    min = percent_threshold.to_i
    next all if percent_threshold.blank? || min <= 0

    matching_ids = to_a.select { |plan| plan.percent_answered >= min }.map(&:id)
    where(id: matching_ids)
  }

  scope :grouped_by_family, lambda {
    order(Arel.sql('COALESCE(plans.belnet_family_id, plans.id) DESC'))
      .order(Arel.sql('CASE WHEN plans.belnet_version = 0 THEN 0 ELSE 1 END ASC'))
      .order(belnet_version: :desc)
  }

  ##
  # Settings for the template
  has_settings :export, class_name: 'Settings::Template' do |s|
    s.key :export, defaults: Settings::Template::DEFAULT_SETTINGS
  end
  alias super_settings settings

  # =============
  # = Callbacks =
  # =============

  # sanitise html tags e.g remove unwanted 'script'
  before_validation lambda { |data|
    data.sanitize_fields(:title, :identifier, :description)
  }

  # =================
  # = Class methods =
  # =================

  # Pre-fetched a plan phase together with its sections and questions
  # associated. It also pre-fetches the answers and notes associated to the plan
  def self.load_for_phase(plan_id, phase_id)
    # Preserves the default order defined in the model relationships
    plan = Plan.joins(template: { phases: { sections: :questions } })
               .preload(template: { phases: { sections: :questions } })
               .where(id: plan_id, phases: { id: phase_id })
               .merge(Plan.includes(answers: :notes)).first
    phase = plan.template.phases.find { |p| p.id == phase_id.to_i }

    [plan, phase]
  end

  # deep copy the given plan and all of it's associations
  # create
  # plan - Plan to be deep copied
  #
  # Returns Plan
  # rubocop:disable Metrics/AbcSize
  def self.deep_copy(plan)
    plan_copy = plan.dup
    plan_copy.title = "Copy of #{plan.title}"
    plan_copy.feedback_requested = false
    # Reset Belnet versioning fields for the copy
    plan_copy.belnet_version = 0
    plan_copy.belnet_family_id = nil

    plan_copy.save!
    # Copy newly generated Id to the identifier
    plan_copy.identifier = plan_copy.id.to_s
    plan.answers.each do |answer|
      answer_copy = Answer.deep_copy(answer)
      plan_copy.answers << answer_copy
    end
    plan.guidance_groups.each do |guidance_group|
      plan_copy.guidance_groups << guidance_group if guidance_group.present?
    end
    plan_copy
  end
  # rubocop:enable Metrics/AbcSize

  # ===========================
  # = Public instance methods =
  # ===========================

  ##
  # Proxy through to the template settings (or defaults if this plan doesn't
  # have an associated template) if there are no settings stored for this plan.
  #
  # TODO: Update this comment below. AFAIK `key` has nothing to do with Rails.
  # key - Is required by rails-settings, so it's required here, too.
  #
  # Returns Hash
  def settings(key)
    self_settings = super_settings(key)
    return self_settings if self_settings.value?

    template&.settings(key)
  end

  # The most recent answer to the given question id optionally can create an answer if
  # none exists.
  #
  # qid               - The id for the question to find the answer for
  # create_if_missing - If true, will genereate a default answer
  #                     to the question (defaults: true).
  #
  # Returns Answer
  # Returns nil
  # rubocop:disable Metrics/AbcSize, Style/OptionalBooleanParameter
  def answer(qid, create_if_missing = true)
    answer = answers.select { |a| a.question_id == qid }
                    .max_by(&:created_at)
    if answer.nil? && create_if_missing
      question = Question.find(qid)
      answer = Answer.new
      answer.plan_id     = id
      answer.question_id = qid
      answer.text        = question.default_value
      default_options    = []
      question.question_options.each do |option|
        default_options << option if option.is_default
      end
      answer.question_options = default_options
    end
    answer
  end
  # rubocop:enable Metrics/AbcSize, Style/OptionalBooleanParameter

  alias get_guidance_group_options guidance_group_options

  deprecate :get_guidance_group_options,
            deprecator: Cleanup::Deprecators::GetDeprecator.new

  ##
  # Sets up the plan for feedback:
  #  emails confirmation messages to owners
  #  emails org admins and org contact
  #  adds org admins to plan with the 'reviewer' Role
  def request_feedback(user)
    Plan.transaction do
      self.feedback_requested = true
      return false unless save!

      # Send an email to the org-admin contact
      if user.org.contact_email.present?
        contact = User.new(email: user.org.contact_email,
                           firstname: user.org.contact_name)
        UserMailer.feedback_notification(contact, self, user).deliver_now
      end
      true
    rescue StandardError => e
      Rails.logger.error e
      false
    end
  end

  ##
  # Finalizes the feedback for the plan: Emails confirmation messages to owners
  # sets flag on plans.feedback_requested to false removes org admins from the
  # 'reviewer' Role for the Plan.
  def complete_feedback(org_admin)
    Plan.transaction do
      self.feedback_requested = false
      return false unless save!

      # Send an email confirmation to the owners and co-owners
      deliver_if(recipients: owner_and_coowners,
                 key: 'users.feedback_provided') do |r|
        UserMailer.feedback_complete(
          r,
          self,
          org_admin
        ).deliver_now
      end
      true
    rescue StandardError => e
      Rails.logger.error e
      false
    end
  end

  ##
  # determines if the plan is editable by the specified user
  #
  # user_id - The id for a user
  #
  # Returns Boolean
  def editable_by?(user_id)
    roles.any? { |r| r.user_id == user_id && r.active && r.editor }
  end

  ##
  # determines if the plan is readable by the specified user
  #
  # user_id - The Integer id for a user
  #
  # Returns Boolean
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def readable_by?(user_id)
    return true if commentable_by?(user_id)

    current_user = User.find(user_id)
    return false unless current_user.present?

    # If the user is a super admin and the config allows for supers to view plans
    if current_user.can_super_admin? && Rails.configuration.x.plans.super_admins_read_all
      true
    # If the user is an org admin and the config allows for org admins to view plans
    elsif current_user.can_org_admin? && Rails.configuration.x.plans.org_admins_read_all
      owner_and_coowners.map(&:org_id).include?(current_user.org_id)
    else
      false
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # determines if the plan is readable by the specified user.
  #
  # user_id - The Integer id for a user
  #
  # Returns Boolean
  def commentable_by?(user_id)
    roles.any? { |r| r.user_id == user_id && r.active && r.commenter } ||
      reviewable_by?(user_id)
  end

  # determines if the plan is administerable by the specified user
  #
  # user_id - The Integer id for the user
  #
  # Returns Boolean
  def administerable_by?(user_id)
    roles.any? { |r| r.user_id == user_id && r.active && r.administrator }
  end

  # determines if the plan is reviewable by the specified user
  #
  # user_id - The Integer id for the user
  #
  # Returns Boolean
  def reviewable_by?(user_id)
    reviewer = User.find(user_id)
    feedback_requested? &&
      reviewer.present? &&
      reviewer.org_id == owner&.org_id &&
      reviewer.can_review_plans?
  end

  # determines if the plan is submittable by the specified user
  #
  # user_id - The Integer id for the user
  #
  # Returns Boolean
  def submittable_by?(user_id)
    submitter = User.find_by(id: user_id)
    return false if submitter.blank?

    is_authorized_user = editable_by?(user_id) ||
                         submitter.can_super_admin? ||
                         (submitter.can_org_admin? && submitter.org_id == org_id)

    is_authorized_user && is_plan_live_version?
  end

  def latest_belnet_version
    # family_id can be nil so in that case it is just 0
    return 0 if belnet_family_id.nil?

    Plan.where(belnet_family_id: belnet_family_id).maximum(:belnet_version)
  end

  def plan_versions
    return Plan.none if belnet_family_id.nil?

    Plan.where(belnet_family_id: belnet_family_id).where('belnet_version > ?', 0)
  end

  def plan_versions_with_live_version
    return Plan.none if belnet_family_id.nil?

    Plan.where(belnet_family_id: belnet_family_id)
  end

  def is_plan_live_version?
    belnet_version == 0
  end

  def update_stage(new_stage_name, current_user)
    new_stage_name = new_stage_name.to_s
    return false unless org&.current_valid_belnet_stages&.include?(new_stage_name)

    apply_belnet_stage_change(new_stage_name, current_user)
  end

  def current_lifecycle_stage_name
    if is_plan_live_version?
      belnet_editable_plan_metadata&.lifecycle_stage.presence
    else
      belnet_version_metadata&.lifecycle_stage.presence
    end
  end

  # Creates a new version of the plan with the same family_id and an incremented version number.
  # The original plan will have its family_id set if it doesn't already have one.
  # Returns the new version of the plan.
  def create_plan_with_new_version!(reason: nil, current_user: nil, original_plan: nil, new_stage: nil)
    # Transaction to ensure that the original plan and the new version are updated/created together
    transaction do
      # Handle family_id logic on the original
      update!(belnet_family_id: id) if belnet_family_id.nil?

      # TODO: disallow the saving of new version if a plan in an array of the same
      # family_ids already has a plan with belnet_version 0

      # Build the new version
      new_version = dup
      new_version.assign_attributes(
        belnet_version: latest_belnet_version + 1,
        belnet_family_id: belnet_family_id || id
      )

      # Copy over the answers, guidance groups and roles (users) to the new version
      original_plan.answers.each do |answer|
        answer_copy = Answer.deep_copy(answer)
        new_version.answers << answer_copy
      end
      original_plan.guidance_groups.each do |guidance_group|
        new_version.guidance_groups << guidance_group if guidance_group.present?
      end
      original_plan.roles.each do |role|
        role_copy = role.dup
        new_version.roles << role_copy
      end

      new_version.save!(context: :versioning)

      # Version metadata
      metadata = BelnetPlanVersionMetadata.new(
        plan: new_version,
        editable_plan: original_plan,
        versioned_plan: new_version,
        created_by: current_user,
        updated_by: current_user,
        reason: reason || '',
        lifecycle_stage: new_stage.to_s.presence
      )
      metadata.save!(context: :versioning)

      # Add the current user as the creator of the new version
      new_version.add_user!(current_user.id, :creator) if current_user.present?
      # Return the new version
      new_version
    end
  end

  # Makes sure that plan has a belnet_editable_plan_metadata record
  # and updates it with the current user and lifecycle_stage if provided.
  def ensure_editable_metadata!(current_user: nil, lifecycle_stage: nil)
    return unless is_plan_live_version?

    metadata = belnet_editable_plan_metadata || build_belnet_editable_plan_metadata
    metadata.created_by ||= current_user
    metadata.updated_by   = current_user
    metadata.lifecycle_stage = lifecycle_stage if lifecycle_stage
    metadata.save!
    metadata
  end

  # Touches version metadata, can only be done on version
  # Used by UI and API
  def touch_version_metadata!(current_user)
    return if is_plan_live_version?

    metadata = belnet_version_metadata
    if metadata.nil?
      editable = Plan.find_by(belnet_family_id: belnet_family_id, belnet_version: 0)
      metadata = BelnetPlanVersionMetadata.new(
        plan: self,
        editable_plan: editable,
        versioned_plan: self,
        created_by: current_user,
        lifecycle_stage: current_lifecycle_stage_name
      )
    end
    metadata.updated_by = current_user
    metadata.updated_at = Time.current
    metadata.save!
    metadata
  end

  # the datetime for the latest update of this plan
  #
  # Returns DateTime
  def latest_update
    (phases.pluck(:updated_at) + [updated_at]).max
  end

  # The owner (aka :creator) of the project
  #
  # Returns User
  # Returns nil
  def owner
    r = roles.select { |rr| rr.active && rr.administrator }
             .min_by(&:created_at)
    r&.user
  end

  # Creates a role for the specified user (will update the user's
  # existing role if it already exists)
  #
  # Expects a User.id and access_type from the following list:
  #  :creator, :administrator, :editor, :commenter
  #
  # Returns Boolean
  def add_user!(user_id, access_type = :commenter)
    user = User.where(id: user_id).first
    if user.present?
      role = Role.find_or_initialize_by(user_id: user_id, plan_id: id)

      # Access is cumulative, so set the appropriate flags
      # (e.g. an administrator can also edit and comment)
      case access_type
      when :creator
        role.creator = true
        role.administrator = true
        role.editor = true
      when :administrator
        role.administrator = true
        role.editor = true
      when :editor
        role.editor = true
      end
      role.commenter = true
      role.save
    else
      false
    end
  end

  ##
  # Whether or not the plan is associated with users other than the creator
  #
  # Returns Boolean
  def shared?
    roles.select(&:active).reject(&:creator).any?
  end

  alias shared shared?

  deprecate :shared, deprecator: Cleanup::Deprecators::PredicateDeprecator.new

  # The owner and co-owners (aka :creator and :administrator) of the project
  #
  # Returns ActiveRecord::Relation
  def owner_and_coowners
    # We only need to search for :administrator in the bitflag
    # since :creator includes :administrator rights
    roles.select { |r| r.active && r.administrator && !r.user.nil? }.map(&:user).uniq
  end

  # The creator, administrator and editors
  #
  # Returns ActiveRecord::Relation
  def authors
    # We only need to search for :editor in the bitflag
    # since :creator and :administrator include :editor rights
    roles.select { |r| r.active && r.editor }.map(&:user).uniq
  end

  # The number of answered questions from the entire plan
  #
  # Returns Integer
  def num_answered_questions(phase = nil)
    return answers.count(&:answered?) unless phase.present?

    answered = answers.select do |answer|
      answer.answered? && phase.questions.include?(answer.question)
    end
    answered.length
  end

  # The number of questions for a plan.
  #
  # Returns Integer
  def num_questions
    questions.count
  end

  # Determines whether or not visibility changes are permitted according to the
  # percentage of the plan answered in respect to a threshold defined at
  # application.config
  #
  # Returns Boolean
  def visibility_allowed?
    !is_test? && phases.any? { |phase| phase.visibility_allowed?(self) }
  end

  # Determines whether or not a question (given its id) exists for the self plan
  #
  # Returns Boolean
  def question_exists?(question_id)
    Plan.joins(:questions).exists?(id: id, 'questions.id': question_id)
  end

  # Determines what percentage of the Plan's questions have been num_answered_questions
  #
  def percent_answered
    num_questions = question_ids.length
    return 0 unless num_questions.positive?

    pre_fetched_answers = Answer.includes(:question_options,
                                          question: :question_format)
                                .where(id: answer_ids)
    num_answers = pre_fetched_answers.reduce(0) do |m, a|
      m += 1 if a.answered?
      m
    end
    return 0 unless num_answers.positive?

    (num_answers / num_questions.to_f) * 100
  end

  # Deactivates the plan (sets all roles to inactive and visibility to :private)
  #
  # Returns Boolean
  def deactivate!
    # If no other :creator, :administrator or :editor is attached
    # to the plan, then also deactivate all other active roles
    # and set the plan's visibility to :private
    if authors.empty?
      roles.where(active: true).update_all(active: false)
      self.visibility = Plan.visibilities[:privately_visible]
      save!
    else
      false
    end
  end

  # Returns the plan's identifier (either a DOI/ARK)
  def landing_page
    identifiers.find { |i| DMP_ID_TYPES.include?(i.identifier_format) }
  end

  def validation_summary
    governance_validations
      .order(created_at: :desc)
      .each_with_object({}) do |validation, summary|
        next if validation.validation_status.blank?

        summary[validation.validation_topic] ||= validation.validation_status
      end
  end

  # Filters governance_validations down to those whose topic name still
  # appears in the org's active validation topic config
  def governance_validations_for_org_topics
    return governance_validations.none if org.nil?

    governance_validations.where(validation_topic: org.active_validation_topics)
  end

  # Since the Grant is not a normal AR association, override the getter and setter
  def grant
    Identifier.find_by(id: grant_id)
  end

  # Helper method to convert the grant id value entered by the user into an Identifier
  # works with both controller params or an instance of Identifier
  # rubocop:disable Metrics/CyclomaticComplexity
  def grant=(params)
    val = params.present? ? params[:value] : nil
    current = grant

    # Remove it if it was blanked out by the user
    current.destroy if current.present? && !val.present?
    return unless val.present?

    # Create the Identifier if it doesn't exist and then set the id
    current.update(value: val) if current.present? && current.value != val
    return if current.present?

    current = Identifier.create(identifiable: self, value: val)
    self.grant_id = current.id
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  public

  attr_reader :last_stage_change_errors

  private

  def apply_belnet_stage_change(new_stage_name, current_user)
    @last_stage_change_errors = nil
    return false if new_stage_name.blank? || current_lifecycle_stage_name == new_stage_name

    old_name = current_lifecycle_stage_name.presence || _('None')
    motivation = if current_lifecycle_stage_name.present?
                   "Stage changed from #{old_name} to #{new_stage_name}"
                 else
                   "Stage set to #{new_stage_name}"
                 end

    transaction do
      persist_stage_metadata(new_stage_name, current_user)
      BelnetStageHistory.create!(
        plan: self,
        lifecycle_stage: new_stage_name,
        user: current_user,
        motivation: motivation
      )
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @last_stage_change_errors = e.record.errors.full_messages
    false
  rescue ActiveRecord::RecordNotSaved
    false
  end

  # All stage changes go through the metadata tables
  def persist_stage_metadata(new_stage_name, current_user)
    if is_plan_live_version?
      metadata = belnet_editable_plan_metadata || build_belnet_editable_plan_metadata(created_by: current_user)
      metadata.updated_by = current_user
      metadata.lifecycle_stage = new_stage_name
      metadata.save!
    else
      metadata = belnet_version_metadata
      if metadata.nil?
        # Version predates the metadata rollout; create a record on first
        # stage change so the new storage is populated going forward.
        editable = Plan.find_by(belnet_family_id: belnet_family_id, belnet_version: 0)
        metadata = BelnetPlanVersionMetadata.new(
          plan: self,
          editable_plan: editable,
          versioned_plan: self,
          created_by: current_user
        )
      end
      metadata.updated_by = current_user
      metadata.lifecycle_stage = new_stage_name
      metadata.save!
    end
  end

  # Validation to prevent end date from coming before the start date
  def end_date_after_start_date
    # allow nil values
    return true if end_date.blank? || start_date.blank?

    errors.add(:end_date, _('must be after the start date')) if end_date < start_date
  end
end
# rubocop:enable Metrics/ClassLength
