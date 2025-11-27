module OmniauthCallbacksControllerExtension
  extend ActiveSupport::Concern

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
