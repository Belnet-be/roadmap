# frozen_string_literal: true

# After an ORCID login with several verified email addresses (see handle_orcid in
# ugent/lib/module_overrides.rb) the user chooses which address to log in with:
# the existing account of that address, or a new account when it has none yet.
# One email address always yields the same account.
class Ugent::SelectableUserController < ApplicationController

  # the choice must be made shortly after the ORCID login, so an abandoned choice
  # (e.g. on a shared computer) cannot be used later on
  ORCID_LOGIN_TTL = 15.minutes.to_i

  before_action :require_orcid_login

  def edit
    render :edit
  end

  def update
    user_params = params.require(:selectable_user).permit(:email)

    email = user_params[:email].to_s.strip.downcase

    # only the verified addresses of the ORCID login can be chosen
    unless @emails.include?(email)

      redirect_to edit_selectable_user_path, alert: "Invalid email address selected"
      return

    end

    user = @accounts[email]

    if user

      # set firstname and surname when not present yet
      user.firstname = @orcid_login["first_name"] if user.firstname.blank? || user.firstname == User.nemo
      user.surname = @orcid_login["last_name"] if user.surname.blank? || user.surname == User.nemo

    else

      user = User.new(
        email: email,
        firstname: @orcid_login["first_name"],
        surname: @orcid_login["last_name"]
      )

      unless user.save

        redirect_to edit_selectable_user_path, alert: user.errors.full_messages.join("<br>")
        return

      end

    end

    # link the ORCID iD when the account has none yet
    if user.identifier_orcid.nil?
      Identifier.create(identifier_scheme: User.identifier_scheme_orcid,
                        value: @orcid_login["uid"],
                        attrs: { "info" => { "email" => @emails.first, "verified_emails" => @emails } },
                        identifiable: user)
    end

    session.delete(:orcid_login)
    sign_in user
    redirect_to root_path
  end

  private

  def require_orcid_login
    @orcid_login = session[:orcid_login]

    if user_signed_in?

      redirect_to root_path, alert: "Already logged in"

    elsif !@orcid_login.is_a?(Hash) || Time.now.to_i - @orcid_login["created_at"].to_i > ORCID_LOGIN_TTL

      session.delete(:orcid_login)
      redirect_to root_path, alert: "Your ORCID login has expired, please log in with ORCID again"

    else

      @emails = Array(@orcid_login["emails"])

      # existing accounts by email address (case insensitive)
      @accounts = User.where("LOWER(email) IN (?)", @emails)
                      .index_by { |u| u.email.downcase }

    end
  end

end
