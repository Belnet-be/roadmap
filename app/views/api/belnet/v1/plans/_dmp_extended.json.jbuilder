# frozen_string_literal: true

# locals: plan, live_plan, validations

json.title plan.title
json.created plan.created_at.to_formatted_s(:iso8601)
json.modified plan.updated_at.to_formatted_s(:iso8601)

json.dmp_id do
  json.identifier "#{request.base_url}/api/belnet-v1/plans/#{live_plan.id}"
  json.type 'url'
end

json.extension do
  json.dmproadmap do
    json.template do
      json.id plan.template.id
      json.title plan.template.title
    end
  end

  belnet_extension = plan.is_plan_live_version? ? plan.belnet_editable_plan_metadata.present? : true
  if belnet_extension
    json.belnet do
      if plan.is_plan_live_version?
        json.dmp_extension_type 'editable'
        json.dmp_editable do
          json.partial! 'api/belnet/v1/plans/belnet_editable',
                        plan: plan, metadata: plan.belnet_editable_plan_metadata
        end
      else
        json.dmp_extension_type 'version'
        json.dmp_version do
          json.partial! 'api/belnet/v1/plans/belnet_version', version: plan
        end
      end

      json.dmp_validations validations do |validation|
        json.dmp_validation do
          json.partial! 'api/belnet/v1/validations/dmp_validation', validation: validation
        end
      end
    end
  end
end