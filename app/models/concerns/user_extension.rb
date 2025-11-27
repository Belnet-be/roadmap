# frozen_string_literal: true

module UserExtension
  extend ActiveSupport::Concern

  included do
    before_validation do |user|
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

    before_invitation_created do |user|
      # fix auto generated names (during invitation in roles controller)
      # fix this in User.before_validation does not work (not validated?)
      user.firstname = User.nemo if user.firstname == 'First Name'
      user.surname = User.nemo if user.surname == 'Surname'
    end
  end

  # There are 2 types of methods, class methods and instance methods
  # Instance methods are called on instances of the class (user.method)

  class_methods do
    def nemo?
      firstname.blank? || surname.blank? || firstname == User.nemo || surname == User.nemo
    end

    def identifier_orcid
      scheme = User.identifier_scheme_orcid
      identifiers.select { |id| id.identifier_scheme_id == scheme.id }.first
    end

    def org_from_email(email)
      parts_email = email.split('@')

      org_domain = Ugent::OrgDomain.where(name: parts_email[1])
                                   .first
      org_domain.present? ? org_domain.org : Org.guest
    end

    def orcid_logo
      'https://orcid.org/sites/default/files/images/orcid_16x16.png'
    end
  end

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

  def self.identifier_scheme_orcid
    @identifier_scheme_orcid ||= IdentifierScheme.find_by_name('orcid')
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

  def set_org_by_email
    self.org = User.org_from_email(email)
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
