# frozen_string_literal: true

# locals: plan

json.dmp_id do
  json.identifier "#{request.base_url}/api/belnet-v1/plans/#{plan.id}"
  json.type 'url'
end

json.title plan.title

json.extension [plan] do |item|
  json.set! :belnet do
    if item.is_plan_live_version?
      json.set! :dmp_extension_type, 'editable'
      json.set! :dmp_editable do
        json.lifecycle_stage item.current_lifecycle_stage_name
      end
    else
      json.set! :dmp_extension_type, 'version'
      json.set! :dmp_version do
        json.number item.belnet_version
        json.lifecycle_stage item.current_lifecycle_stage_name
      end
    end
  end
end
