# frozen_string_literal: true

# locals: validation

json.partial! 'api/belnet/v1/standard_response', total_items: 1

json.items [validation] do |item|
  json.dmp_validation do
    json.partial! 'api/belnet/v1/validations/dmp_validation', validation: item
  end
end
