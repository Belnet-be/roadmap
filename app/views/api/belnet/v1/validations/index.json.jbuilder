# frozen_string_literal: true

json.partial! 'api/belnet/v1/standard_response', total_items: @total_items

json.items @items do |validation|
  json.dmp_validation do
    json.partial! 'api/belnet/v1/validations/dmp_validation', validation: validation
  end
end
