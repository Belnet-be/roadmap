# frozen_string_literal: true

module Api
  module V1
    module Deserialization
      # Logic to deserialize RDA common standard to a Contributor object
      class Contributor
        class << self
          # Convert the incoming JSON into a Contributor
          #   {
          #     "role": [
          #       "http://credit.niso.org/contributor-roles/project-administration"
          #     ],
          #     "name": "Jane Doe",
          #     "mbox": "jane.doe@university.edu",
          #     "affiliation": {
          #       "name": "University of Somewhere",
          #       "abbreviation": "UofS",
          #       "affiliation_id": {
          #         "type": "ror",
          #         "identifier": "https://ror.org/43y4g4"
          #       }
          #     },
          #     "contributor_id": {
          #       "type": "orcid",
          #       "identifier": "0000-0000-0000-0000"
          #     }
          #   }
          def deserialize(json: {}, is_contact: false)
            return nil unless Api::V1::JsonValidationService.contributor_valid?(
              json: json, is_contact: is_contact
            )

            json = json.with_indifferent_access

            # Build the Contributor from the submitted data
            id_json = json.fetch(:contributor_id, json.fetch(:contact_id, {}))
            contrib = new_contributor(json: json)
            return nil unless contrib.present?

            # Attach the Org unless its already defined
            contrib.org = Api::V1::Deserialization::Org.deserialize(json: json[:affiliation])

            # Attach the identifier
            contrib = Api::V1::DeserializationService.attach_identifier(
              object: contrib, json: id_json
            )

            # Assign the roles
            contrib = assign_contact_roles(contributor: contrib) if is_contact
            assign_roles(contributor: contrib, json: json)
          end

          # ===================
          # = PRIVATE METHODS =
          # ===================

          private

          # Each plan's contributors are its own records, built from the submitted data only.
          # Never start from another plan's contributor found by ORCID iD or email: that copies
          # someone else's details (name, email, phone, organisation) into this plan and into
          # the API response.
          def new_contributor(json: {})
            return nil unless json.present?

            ::Contributor.new(name: json[:name], email: json[:mbox])
          end

          # Assign the default Contact roles
          def assign_contact_roles(contributor:)
            return contributor unless contributor.present?

            contributor.data_curation = true
            contributor
          end

          # Assign the specified roles
          def assign_roles(contributor:, json: {})
            return contributor unless contributor.present? && json.present? && json[:role].present?

            json.fetch(:role, []).each do |url|
              role = Api::V1::DeserializationService.translate_role(role: url)
              contributor.send(:"#{role}=", true) if role.present?
            end
            contributor
          end
        end
      end
    end
  end
end
