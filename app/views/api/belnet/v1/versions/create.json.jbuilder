# frozen_string_literal: true

# locals: version

json.partial! 'api/belnet/v1/standard_response', total_items: 1

json.items [version] do |item|
  json.dmp_version do
    json.partial! 'api/belnet/v1/versions/dmp_version', version: item,
                                                       created_by_user: created_by_user
  end
end
