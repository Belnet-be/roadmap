# frozen_string_literal: true

# locals: plan

json.partial! 'api/belnet/v1/standard_response', total_items: 1

json.items [plan] do |item|
  json.dmp do
    json.partial! 'api/belnet/v1/plans/versions/show', plan: item
  end
end
