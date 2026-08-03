# frozen_string_literal: true

# locals: plan, lifecycle_stage

json.partial! 'api/belnet/v1/standard_response', total_items: 1

json.items [plan] do |item|
  json.dmp_editable do
    json.partial! 'api/belnet/v1/plans/lifecycle-stage/show', plan: item,
                                                             lifecycle_stage: lifecycle_stage
  end
end
