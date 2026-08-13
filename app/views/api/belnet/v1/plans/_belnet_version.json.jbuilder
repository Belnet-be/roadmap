# frozen_string_literal: true

# locals: version (a Plan snapshot, belnet_version > 0)

metadata = version.belnet_version_metadata

created_at    = metadata&.created_at || version.created_at
modified_at   = metadata&.updated_at || version.updated_at
created_user  = metadata&.created_by
modified_user = metadata&.updated_by

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

json.dmp_id do
  json.identifier "#{request.base_url}/api/belnet-v1/plans/#{version.id}"
  json.type 'url'
end

json.number version.belnet_version
json.reason metadata&.reason
json.lifecycle_stage version.current_lifecycle_stage_name
