# frozen_string_literal: true

# locals: plan, live_plan, validations

presenter = Api::V1::PlanPresenter.new(plan: plan)

json.title plan.title
json.description plan.description
json.language Api::V1::LanguagePresenter.three_char_code(lang: LocaleService.default_locale)
json.created plan.created_at.to_formatted_s(:iso8601)
json.modified plan.updated_at.to_formatted_s(:iso8601)

json.ethical_issues_exist Api::V1::ConversionService.boolean_to_yes_no_unknown(plan.ethical_issues)
json.ethical_issues_description plan.ethical_issues_description
json.ethical_issues_report plan.ethical_issues_report

# top level dmp_id poiint to live plan
json.dmp_id do
  json.identifier "#{request.base_url}/api/belnet-v1/plans/#{live_plan.id}"
  json.type 'url'
end

if presenter.data_contact.present?
  json.contact do
    json.partial! 'api/belnet/v1/contributors/show', contributor: presenter.data_contact,
                                                     is_contact: true
  end
end

if presenter.contributors.any?
  json.contributor presenter.contributors do |contributor|
    json.partial! 'api/belnet/v1/contributors/show', contributor: contributor,
                                                     is_contact: false
  end
end

if presenter.costs.any?
  json.cost presenter.costs do |cost|
    json.partial! 'api/belnet/v1/plans/versions/cost', cost: cost
  end
end

json.project [plan] do |pln|
  json.partial! 'api/belnet/v1/plans/versions/project', plan: pln
end

outputs = plan.research_outputs.any? ? plan.research_outputs : [plan]
json.dataset outputs do |output|
  json.partial! 'api/belnet/v1/datasets/show', output: output
end

# The extension array carries the dmproadmap template info plus the belnet
# block. The belnet block's shape is driven by `dmp_extension_type`.
json.extension [plan.template] do |template|
  json.set! :dmproadmap do
    json.template do
      json.id template.id
      json.title template.title
    end
  end

  json.set! :belnet do
    if plan.is_plan_live_version?
      json.set! :dmp_extension_type, 'editable'
      metadata = plan.belnet_editable_plan_metadata

      json.set! :dmp_editable do
        json.partial! 'api/belnet/v1/plans/belnet_editable',
                      plan: plan, metadata: metadata
      end
    else
      json.set! :dmp_extension_type, 'version'

      json.set! :dmp_version do
        json.partial! 'api/belnet/v1/plans/belnet_version', version: plan
      end
    end

    json.set! :dmp_validations, validations do |validation|
      json.dmp_validation do
        json.partial! 'api/belnet/v1/validations/dmp_validation', validation: validation
      end
    end
  end
end
