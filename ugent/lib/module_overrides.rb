# frozen_string_literal: true

module PlansHelper
  def download_plan_page_title(plan, phase, hash)
    # If there is more than one phase show the plan title and phase title
    hash[:phases].many? ? "#{plan.title} <p>#{phase[:title]}</p>".html_safe : plan.title
  end

  def display_user(user)
    return _('You') if user.id == current_user.id

    user.email
  end
end

# class PlanExportsController

#   def file_name
#     p = "plan_#{@plan.id}"
#     if @selected_phases.length == 1
#       p += "_phase_#{@selected_phases.first.id}"
#     end
#     p += "_#{@plan.updated_at.utc.strftime("%Y%m%dT%H%M%SZ")}"
#     p
#   end

#   def show

#     # COPY FROM ORIGINAL PlanExportsController#show
#     @plan = Plan.includes(:answers, { template: { phases: { sections: :questions } } })
#                 .find(params[:plan_id])

#     # preliminary fix for https://github.com/DMPRoadmap/roadmap/issues/3345
#     if privately_authorized?
#       skip_authorization

#       if export_params[:form].present?

#         @show_coversheet         = export_params[:project_details].present?
#         @show_sections_questions = export_params[:question_headings].present?
#         @show_unanswered         = export_params[:unanswered_questions].present?
#         @show_custom_sections    = export_params[:custom_sections].present?
#         @show_research_outputs   = export_params[:research_outputs].present?
#         @public_plan             = false

#       else

#         @show_coversheet         = true
#         @show_sections_questions = true
#         @show_unanswered         = true
#         @show_custom_sections    = true
#         @show_research_outputs   = @plan.research_outputs&.any? || false
#         @public_plan             = false

#       end

#     elsif publicly_authorized?
#       skip_authorization

#       @show_coversheet         = true
#       @show_sections_questions = true
#       @show_unanswered         = true
#       @show_custom_sections    = true
#       @show_research_outputs   = @plan.research_outputs&.any? || false
#       @public_plan             = true

#     else

#       raise Pundit::NotAuthorizedError

#     end

#     @formatting      = export_params[:formatting] || @plan.settings(:export).formatting
#     @selected_phases = if params.key?(:phase_id)
#                           @plan.phases.where(id: params[:phase_id]).all
#                        else
#                           @plan.phases.sort { |a,b| b.updated_at <=> a.updated_at }
#                        end

#     respond_to do |format|
#       format.html {
#         @hash = @plan.as_pdf(current_user, @show_coversheet)
#         show_html
#       }
#       format.csv  { show_csv }
#       format.text {
#         @hash = @plan.as_pdf(current_user, @show_coversheet)
#         show_text
#       }
#       format.docx {
#         @hash = @plan.as_pdf(current_user, @show_coversheet)
#         show_docx
#       }
#       format.pdf  {
#         @hash = @plan.as_pdf(current_user, @show_coversheet)
#         show_pdf
#       }
#       format.json { show_json }
#     end
#   end

#   def show_csv
#     send_data @plan.as_csv(current_user, @show_sections_questions,
#                            @show_unanswered,
#                            @selected_phases,
#                            @show_custom_sections,
#                            @show_coversheet,
#                            @show_research_outputs),
#               filename: "#{file_name}.csv"
#   end

# end

class PlanPolicy
  # guest user should not be able to access the plan creation wizard
  # action new? determined by create? (see app/models/application_policy.rb)
  def create?
    @user.present? && !@user.guest?
  end
end

class Contributor
  # update contributor based on user data
  # note: only do this for contributors with the same email!
  def update_from_user(user)
    # update user data
    self.name    = user.nemo? ? User.nemo : "#{user.firstname} #{user.surname}"
    self.org_id  = user.org_id

    # update contributor identifier
    scheme_orcid = User.identifier_scheme_orcid
    user_orcid   = user.identifiers
                       .select { |id| id.identifier_scheme_id == scheme_orcid.id }
                       .first

    contr_orcid = nil

    if user_orcid.present?

      contr_orcid = identifiers
                    .select { |id| id.identifier_scheme_id == scheme_orcid.id }
                    .first

      if contr_orcid.nil?

        contr_orcid = identifiers
                      .build(identifier_scheme_id: scheme_orcid.id, value: user_orcid.value)

      else

        contr_orcid.value = user_orcid.value

      end

    end

    identifiers = if contr_orcid.nil?

                    []

                  else

                    [contr_orcid]

                  end
  end

  def self.roles
    @roles ||= %i[investigation data_curation project_administration other].freeze
  end

  # get User record for Contributor, based on email address
  def to_user
    return nil if email.blank?

    User.where(email: email)
        .first
  end
end

# Automatically synchronise user data to contributors
User.after_save do |user|
  next if user.previous_changes.empty?

  Contributor.where(email: user.email)
             .update_all(
               name: user.nemo? ? User.nemo : "#{user.firstname} #{user.surname}",
               org_id: user.org_id
             )
end

# Automatically update/create identifier orcid in Contributor when User orcid is created/updated
Identifier.after_save do |id|
  next if id.previous_changes.empty?

  next unless id.identifiable_type == 'User'

  next unless id.identifier_scheme_id == User.identifier_scheme_orcid.id

  user = id.identifiable

  Contributor.includes(:identifiers)
             .where(email: user.email)
             .each do |contributor|
    orcids = contributor.identifiers.select { |i| i.identifier_scheme_id == User.identifier_scheme_orcid.id }
    next if orcids.size > 0

    contributor.identifiers
               .build(identifier_scheme: User.identifier_scheme_orcid, value: id.value)
               .save
  end
end

# automatically take label from org when no label is provided
Identifier.before_save do |id|
  next unless id.identifiable_type == 'Org'
  next unless id.identifier_scheme.name == 'shibboleth'
  next if id.label.present?

  id.label = id.identifiable.name
end

# if role is removed, automatically remove associated contributor
Role.after_destroy do |role|
  plan = role.plan
  user = role.user
  contributor = plan.contributors
                    .select { |contributor| contributor.email == user.email }
                    .first

  next if contributor.nil?

  Rails.logger.info("Role #{role} is destroyed, so removing associated contributor #{contributor}")
  contributor.destroy
end

# if role is deactivated, also remove associated contributor
Role.after_save do |role|
  next if role.active?

  plan = role.plan
  user = role.user
  contributor = plan.contributors
                    .select { |contributor| contributor.email == user.email }
                    .first

  next if contributor.nil?

  Rails.logger.info("Role #{role} is deactivated, so removing associated contributor #{contributor}")
  contributor.destroy
end

class Plan
  def as_csv(user,
             headings = true,
             unanswered = true,
             selected_phases = nil,
             show_custom_sections = true,
             show_coversheet = false,
             show_research_outputs = false)
    hash = prepare(user, show_coversheet)
    CSV.generate do |csv|
      prepare_coversheet_for_csv(csv, headings, hash) if show_coversheet

      hdrs = (hash[:phases].many? ? [_('Phase')] : [])
      hdrs << if headings
                [_('Section'), _('Question'), _('Answer')]
              else
                [_('Answer')]
              end

      customization = hash[:customization]

      csv << hdrs.flatten
      selected_phase_titles = selected_phases.map(&:title)
      hash[:phases].each do |phase|
        next unless selected_phase_titles.include?(phase[:title])

        phase[:sections].each do |section|
          show_section = !customization
          show_section ||= customization && !section[:modifiable]
          show_section ||= customization && section[:modifiable] && show_custom_sections

          if show_section && num_section_questions(self, section, phase).positive?
            show_section_for_csv(csv, phase, section, headings, unanswered, hash)
          end
        end
      end

      # NOTE: this code override ignores research outputs
    end
  end

  # add missing length validation
  # underlying table attribute only allows for 255 characters
  validates :name, length: { maximum: 255 }

  def principal_investigators
    all_investigators = contributors.all
                                    .select { |c| c.investigation? }
                                    .reject { |c| c.email.blank? }

    emails = all_investigators.map(&:email).uniq

    return [] if emails.empty?

    user_records = User.where(email: emails).all

    # make sure that the users are returned in same order
    # as the corresponding contributors
    users = []

    all_investigators.each do |cc|
      user_records.each do |u|
        users << u if u.email == cc.email
      end
    end

    users
  end
end

class Identifier
  def value_uniqueness_with_scheme
    # override - start
    # Org may have multiple login routes of the same type
    return true if identifier_scheme.name == 'shibboleth' && identifiable_type == 'Org'

    # same orcid may be attached to several users
    return true if identifier_scheme.name == 'orcid' && identifiable_type == 'User'

    # override - end
    # old code
    if new_record? && Identifier.where(identifier_scheme: identifier_scheme,
                                       identifiable: identifiable).any?
      errors.add(:identifier_scheme, _('already assigned a value'))
    end
  end
end

class User
  def ensure_password
    generate_password unless encrypted_password.present?
  end

  def generate_password
    self.password = Devise.friendly_token[0, 20]
    self.password_confirmation = password
  end

  def guest?
    org_id == Org.guest.id
  end

  def self.nemo
    'n.n.'
  end

  def nemo?
    firstname.blank? || surname.blank? || firstname == User.nemo || surname == User.nemo
  end

  def self.identifier_scheme_orcid
    @identifier_scheme_orcid ||= IdentifierScheme.find_by_name('orcid')
  end

  def identifier_orcid
    scheme = User.identifier_scheme_orcid
    identifiers.select { |id| id.identifier_scheme_id == scheme.id }.first
  end

  def alternative_accounts
    orcid = identifier_orcid

    return [] if orcid.nil?

    Identifier.where(
      'identifier_scheme_id = ? AND identifiable_type = ? AND value = ? AND identifiable_id <> ?',
      orcid.identifier_scheme_id,
      'User',
      orcid.value,
      id
    )
              .map(&:identifiable)
  end

  def self.org_from_email(email)
    parts_email = email.split('@')

    org_domain = Ugent::OrgDomain.where(name: parts_email[1])
                                 .first
    org_domain.present? ? org_domain.org : Org.guest
  end

  def set_org_by_email
    self.org = User.org_from_email(email)
  end

  def self.orcid_logo
    'https://orcid.org/sites/default/files/images/orcid_16x16.png'
  end

  # get HTML snippet to show in docx/pdf for User
  def orcid_link
    orcid_id = identifier_orcid
    return nil unless orcid_id.present?

    orcid_id = orcid_id.value

    str = []

    orcid_base_url = 'https://orcid.org'

    str << '<a class="orcid-link" href="'
    str << orcid_base_url
    str << '"><img alt="ORCID logo" src="'
    str << User.orcid_logo
    str << '"></a>'
    str << ' <a class="orcid-link" href="'
    str << orcid_id
    str << '" title="'
    str << orcid_id
    str << '">'
    str << orcid_id
    str << '</a>'

    str.join('').html_safe
  end

  def name_with_orcid
    str = [name(false)]

    l = orcid_link

    str << ' ' << l unless l.nil?

    str.join('').html_safe
  end
end

User.before_validation do |user|
  # downcase email of new user
  if user.new_record?

    user.email.downcase! if user.email.present?

  # do not allow email changes
  # TODO: keep?
  elsif user.email_changed?

    user.email = user.email_was

  end

  # only (re)set organisation during creation
  if user.new_record? || user.org.nil?

    if user.email.present?

      user.set_org_by_email

    else

      user.org = Org.guest

    end

  end

  user.ensure_password
  user.firstname = User.nemo if user.firstname.blank?
  user.surname = User.nemo if user.surname.blank?
end

User.before_invitation_created do |user|
  # fix auto generated names (during invitation in roles controller)
  # fix this in User.before_validation does not work (not validated?)
  user.firstname = User.nemo if user.firstname == 'First Name'
  user.surname   = User.nemo if user.surname == 'Surname'
end

class Devise::Mailer
  # devise mailer does not use app/views/branded as stated by rails
  # purpose: when a user is added to a plan, an invitation mail is
  # and for existing user a sharing notification mail. We made sure
  # here that the invitation mail looks the same as the sharing notification
  # mail
  prepend_view_path(Rails.root.join('app', 'views', 'branded'))
end

class Org
  has_many :domains, class_name: 'Ugent::OrgDomain'

  # users whose email address does not belong to any organisation domains
  # become part of the guest org
  def self.guest
    where(abbreviation: 'guests').first
  end
end

module Users
  class OmniauthCallbacksController
    after_action do
      if current_user.present? && current_user.invitation_token.present?

        # remove invitation token
        current_user.assign_attributes(
          invitation_token: nil,
          invitation_created_at: nil,
          invitation_sent_at: nil,
          invitation_accepted_at: nil
        )

        # changes during User.before_invitation_created have no effect on create,
        # so we're changing the org here
        current_user.set_org_by_email

        current_user.save!

      end
    end

    def notify_missing_orcid
      return if flash[:notice].present?

      flash[:notice] =
        'Your account is not linked to an ORCID iD. Please go to your <a class="alert-link" href="' + edit_user_registration_url + '">profile</a> and click on the link <strong>"Create or connect your ORCID iD"</strong>.'
    end

    # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
    def handle_shibboleth(scheme)
      auth = request.env['omniauth.auth']

      # uid is email address, and that is always consequently formatted
      auth.uid.downcase!

      # find user by existing identifier
      user = User.from_omniauth(auth)

      # If the user isn't logged in
      if current_user.nil?

        # no user found: two reasons:
        #   1) no user in table users
        #   2) no identifier of scheme shibboleth yet

        user = User.find_by_email(auth.uid) if user.nil?

        # still no user: create one
        if user.nil?

          email = auth['extra'].try('raw_info').try('mail')
          user = User.new(email: email.downcase)
          user.surname = auth['extra'].try('raw_info').try('sn')
          user.firstname = auth['extra'].try('raw_info').try('givenname')

          unless user.save

            flash[:alert] = user.errors
                                .full_messages
                                .join('<br>')
            redirect_to root_path
            return

          end

        end

        # attach shibboleth identifiers for future use
        if user.identifiers
               .select { |id| id.identifier_scheme_id == scheme.id }
               .empty?

          if Identifier.create(identifier_scheme: scheme,
                               value: auth.uid,
                               attrs: auth,
                               identifiable: user)

            flash[:notice] =
              format(_('Your account has been successfully linked to %{scheme}.'), scheme: scheme.description)

          else

            flash[:alert] = format(_('Unable to link your account to %{scheme}.'), scheme: scheme.description)

          end

        end

        # missing orcid?
        notify_missing_orcid unless user.identifier_orcid.present?

        sign_in(user)

      # The user is already logged in and just registering the uid with us
      # If the user could not be found by that uid then attach it to their record
      elsif user.nil?

        if Identifier.create(identifier_scheme: scheme,
                             value: auth.uid,
                             attrs: auth,
                             identifiable: current_user)
          flash[:notice] =
            format(_('Your account has been successfully linked to %{scheme}.'), scheme: scheme.description)

        else

          flash[:alert] = format(_('Unable to link your account to %{scheme}.'), scheme: scheme.description)

        end

      # If a user was found but does NOT match the current user then the identifier has
      # already been attached to another account (likely the user has 2 accounts)
      elsif user.id != current_user.id

        flash[:alert] =
          _("The current #{scheme.description} iD has been already linked to a user with email #{identifier.user.email}")

      end

      # Redirect to root url
      redirect_to root_url
    end
    # rubocop: enable Metrics/MethodLength, Metrics/AbcSize

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def handle_orcid(scheme)
      auth = request.env['omniauth.auth']

      Rails.logger.info("auth: #{auth}")

      # when saved, identifier of scheme "orcid" is prefixed with the identifier_prefix of the corresponding scheme
      full_uid = scheme.identifier_prefix + auth.uid

      # The user is already logged in and just registering the uid with us
      # Action: attach id and redirect to profile page
      if current_user.present?

        Rails.logger.info('found current_user')

        existing_id = current_user.identifiers
                                  .select { |id| id.value == full_uid && id.identifier_scheme_id == scheme.id }
                                  .first

        if existing_id.nil?

          if Identifier.create(identifier_scheme: scheme,
                               value: auth.uid,
                               attrs: auth,
                               identifiable: current_user)
            flash[:notice] =
              format(_('Your account has been successfully linked to %{scheme}.'), scheme: scheme.description)

          else

            flash[:alert] = format(_('Unable to link your account to %{scheme}.'), scheme: scheme.description)

          end

        else

          flash[:alert] = format(_('Your account has already been linked to %{scheme}'), scheme: scheme.description)

        end

        redirect_to edit_user_registration_path
        return

      end

      # User is not logged in
      email = auth['info'].try('email').downcase

      # Match orcid with one of more users
      selectable_users = Identifier.where(identifiable_type: 'User', identifier_scheme_id: scheme.id, value: full_uid)
                                   .map(&:identifiable)
                                   .reject(&:nil?)

      # Also match on primary email address
      # as the user may be registered before with another email
      # address, and he/she is stuck
      selectable_users += User.where(email: email).all

      selectable_users.uniq!

      # TODO: create controller
      if selectable_users.size > 1

        session[:selectable_user_ids] = selectable_users.map(&:id)
        redirect_to edit_selectable_user_path
        return

      end

      Rails.logger.info("selectable_users: #{selectable_users.map(&:attributes)}")

      user = selectable_users.first

      # Match on ORCID: OK
      if user

        # set firstname and surname when not present yet
        user.firstname = auth['info'].try('first_name') if user.firstname.blank? || user.firstname == User.nemo
        user.surname = auth['info'].try('last_name') if user.surname.blank? || user.surname == User.nemo

      # Match on primary email: OK
      # this user's orcid must be empty or different
      # attribute 'email' is unique (enforced by devise?)
      elsif email.present? && (user = User.where(email: email).first)

        existing_id = user.identifiers
                          .select { |id| id.value == full_uid && id.identifier_scheme_id == scheme.id }
                          .first

        if existing_id.nil?

          if Identifier.create(identifier_scheme: scheme,
                               value: auth.uid,
                               attrs: auth,
                               identifiable: user)

            flash[:notice] =
              format(_('Your account has been successfully linked to %{scheme}.'), scheme: scheme.description)

          else

            flash[:alert] = format(_('Unable to link your account to %{scheme}.'), scheme: scheme.description)

          end

        end

      # Match on primary email: false
      # NEW USER. We trust "email" because ORCID marks it as confirmed
      elsif email.present?

        user = User.new(
          email: email,
          firstname: auth['info'].try('first_name'),
          surname: auth['info'].try('last_name')
        )

        unless user.save

          flash[:alert] = user.errors
                              .full_messages
                              .join('<br>')
          return redirect_to root_url

        end

        if Identifier.create(identifier_scheme: scheme,
                             value: auth.uid,
                             attrs: auth,
                             identifiable: user)

          flash[:notice] =
            format(_('Your account has been successfully linked to %{scheme}.'), scheme: scheme.description)

        else

          flash[:alert] = format(_('Unable to link your account to %{scheme}.'), scheme: scheme.description)

        end

      # No orcid, no email: warn user
      else

        flash[:alert] =
          "Unable to login with orcid: try setting the visibility of your email address to \"everyone\" or \"trusted parties\" (<a href=\"https://orcid.org/account\">orcid profile</a>). Do not forget to add this website to your \"Trusted Organisations\" if you're choosing for \"trusted parties\""
        redirect_to root_url
        return

      end

      set_flash_message(:notice, :success, kind: scheme.description) if is_navigational_format?
      sign_in_and_redirect user, event: :authentication
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def handle_omniauth(scheme)
      if scheme.name == 'shibboleth'
        handle_shibboleth(scheme)
      elsif scheme.name == 'orcid'
        handle_orcid(scheme)
      end
    end
  end
end

RolesController.after_action(only: %i[create]) do |controller|
  # only apply when role was persisted, and therefore valid
  next unless @role.persisted?

  # no boxes checked, no parameters sent
  controller.params[:contributor] ||= Hash[Contributor.roles.map { |cr| [cr, 0] }]

  contributor_params = controller.params
                                 .require(:contributor)
                                 .permit(*Contributor.roles)

  contributor = Contributor.where(plan_id: @role.plan_id, email: @role.user.email)
                           .first

  contributor = Contributor.new(plan_id: @role.plan_id, email: @role.user.email) if contributor.nil?

  contributor.roles = 0

  Contributor.roles.each do |contributor_access|
    if contributor_params.key?(contributor_access.to_s)
      contributor.send("#{contributor_access}=", contributor_params[contributor_access])
    end
  end

  if contributor.roles == 0

    contributor.destroy if contributor.persisted?

  else

    contributor.update_from_user(@role.user)
    contributor.save!

  end
end

# add method update_role_with_contributor? for controller Ugent::RolesController#update_role_with_contributor
class PlanPolicy
  def update_role_with_contributor?
    @record.administerable_by?(@user.id)
  end
end

Settings::Template::DEFAULT_SETTINGS[:formatting][:font_size] = 14
