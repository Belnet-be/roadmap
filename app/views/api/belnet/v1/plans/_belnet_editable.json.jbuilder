# frozen_string_literal: true

# locals: plan, metadata (BelnetEditablePlanMetadata or nil)

created_at   = metadata&.created_at || plan.created_at
modified_at  = metadata&.updated_at || plan.updated_at
created_user = metadata&.created_by || plan.owner
modified_user = metadata&.updated_by || plan.owner

json.created  created_at.strftime('%Y-%m-%d %H:%M')
json.modified modified_at.strftime('%Y-%m-%d %H:%M')

created_orcid = created_user&.identifier_for_scheme(scheme: 'orcid')
if created_orcid.present?
  json.created_by do
    json.identifier created_orcid.value
    json.type created_orcid.identifier_format
  end
end

modified_orcid = modified_user&.identifier_for_scheme(scheme: 'orcid')
if modified_orcid.present?
  json.modified_by do
    json.identifier modified_orcid.value
    json.type modified_orcid.identifier_format
  end
end

json.lifecycle_stage plan.current_lifecycle_stage_name
