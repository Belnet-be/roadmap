# frozen_string_literal: true

# locals: plan, lifecycle_stage

metadata = plan.belnet_editable_plan_metadata

created_at = metadata&.created_at || plan.created_at
modified_at = metadata&.updated_at || plan.updated_at
created_by_user = metadata&.created_by || plan.owner
modified_by_user = metadata&.updated_by || plan.owner

json.created created_at.strftime('%Y-%m-%d %H:%M')
json.modified modified_at.strftime('%Y-%m-%d %H:%M')

created_by_orcid = created_by_user&.identifier_for_scheme(scheme: 'orcid')
if created_by_orcid.present?
  json.created_by do
    json.identifier created_by_orcid.value
    json.type created_by_orcid.identifier_format
  end
end

modified_by_orcid = modified_by_user&.identifier_for_scheme(scheme: 'orcid')
if modified_by_orcid.present?
  json.modified_by do
    json.identifier modified_by_orcid.value
    json.type modified_by_orcid.identifier_format
  end
end

json.set! 'lifecycle-stage', plan.current_lifecycle_stage_name || lifecycle_stage.to_s.presence
