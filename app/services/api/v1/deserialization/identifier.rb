# frozen_string_literal: true

module Api
  module V1
    module Deserialization
      # Logic to deserialize RDA common standard to an Identifier object
      class Identifier
        class << self
          # Convert the incoming JSON into a new Identifier
          #    {
          #      "type": "ror",
          #      "identifier": "https://ror.org/43y4g4"
          #    }
          # Always a new record with the submitted value. Never return an existing Identifier:
          # attaching it to the new object would move it away from the contributor, org or plan
          # it belongs to. Use DeserializationService.object_from_identifier to find a record by
          # its identifier.
          def deserialize(class_name:, json: {})
            return nil unless class_name.present? &&
                              Api::V1::JsonValidationService.identifier_valid?(json: json)

            json = json.with_indifferent_access
            scheme = ::IdentifierScheme.by_name(json[:type].downcase).first
            ::Identifier.new(identifier_scheme: scheme, value: json[:identifier])
          end
        end
      end
    end
  end
end
