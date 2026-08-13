# frozen_string_literal: true

# locals: plan, live_plan, validations

json.partial! 'api/belnet/v1/standard_response', total_items: 1

json.items [plan] do |item|
  json.dmp do
    json.partial! 'api/belnet/v1/plans/dmp', plan: item,
                                             live_plan: live_plan,
                                             validations: validations
  end
end
