# frozen_string_literal: true

# Belnet security tasks

namespace :belnet do
  namespace :security do
    # ORCID logins before 2023 stored ORCID's access and refresh token in identifiers.attrs
    # ("credentials"). DMPonline never uses them, so they are only a risk: remove them and keep
    # the rest of the login answer (provider and uid mark a confirmed ORCID link).
    # Dry run by default: APPLY=1 writes.
    desc 'Remove the OAuth tokens stored with login identifiers (dry run; APPLY=1 removes them)'
    task remove_stored_login_tokens: :environment do
      apply = ENV['APPLY'] == '1'
      found = 0

      Identifier.where('attrs LIKE ?', '%"credentials"%').find_each do |identifier|
        attrs = begin
          JSON.parse(identifier.attrs.to_s)
        rescue JSON::ParserError
          next
        end
        # Shibboleth logins store an empty "credentials": nothing to remove there
        next unless attrs.is_a?(Hash) && attrs['credentials'].present?

        found += 1
        # update_column: no callbacks. A save would run Belnet's Identifier.after_save, which copies
        # ORCID iDs to contributors.
        identifier.update_column(:attrs, attrs.except('credentials').to_json) if apply
      end

      result = apply ? 'removed' : 'found (dry run: APPLY=1 removes them)'
      puts "Stored login tokens #{result}: #{found} identifiers"
    end
  end
end
