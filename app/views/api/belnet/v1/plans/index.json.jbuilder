# frozen_string_literal: true

json.partial! 'api/belnet/v1/standard_response', total_items: @total_items

json.items @items do |plan|
  json.dmp do
    case @depth
    when 'id'
      json.partial! 'api/belnet/v1/plans/dmp_id', plan: plan
    when 'extended'
      live_plan   = live_plan_for(plan)
      validations = validations_for(plan, live_plan)
      json.partial! 'api/belnet/v1/plans/dmp_extended',
                    plan: plan, live_plan: live_plan, validations: validations
    else
      json.partial! 'api/belnet/v1/plans/dmp_summary', plan: plan
    end
  end
end
