# frozen_string_literal: true

# locals: version, created_by_user (optional)

json.dmp_id do
  json.identifier "#{request.base_url}/api/belnet-v1/plans/#{version.id}"
  json.type 'url'
end

json.number version.belnet_version
json.created version.created_at.utc.iso8601

user = local_assigns[:created_by_user]
user ||= User.includes(:identifiers).find_by(id: version.belnet_created_by) if version.belnet_created_by.present?
created_by_orcid = user&.identifier_for_scheme(scheme: 'orcid')
if created_by_orcid.present?
  json.created_by do
    json.identifier created_by_orcid.value
    json.type created_by_orcid.identifier_format
  end
end

json.reason version.belnet_reason
json.set! 'lifecycle-stage', version.current_lifecycle_stage_name
