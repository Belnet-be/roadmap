# frozen_string_literal: true

json.partial! 'api/belnet/v1/standard_response', total_items: @total_items

json.items @items do |version|
  json.dmp_version do
    json.partial! 'api/belnet/v1/versions/dmp_version', version: version
  end
end
