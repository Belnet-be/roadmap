# frozen_string_literal: true

# locals: version, created_by_user (optional)

metadata = version.belnet_version_metadata

json.dmp_id do
  json.identifier "#{request.base_url}/api/belnet-v1/plans/#{version.id}"
  json.type 'url'
end

json.number version.belnet_version
json.created version.created_at.utc.iso8601

# modified and modified by are only emitted when the version was updated (touched)
json.modified metadata.updated_at.utc.iso8601 if metadata && metadata.updated_at != metadata.created_at

created_by_user = local_assigns[:created_by_user] ||
                  metadata&.created_by ||
                  (version.belnet_created_by.present? ? User.includes(:identifiers).find_by(id: version.belnet_created_by) : nil)

created_by_orcid = created_by_user&.identifier_for_scheme(scheme: 'orcid')
if created_by_orcid.present?
  json.created_by do
    json.identifier created_by_orcid.value
    json.type created_by_orcid.identifier_format
  end
end

if metadata && metadata.updated_at != metadata.created_at
  modified_by_orcid = metadata.updated_by&.identifier_for_scheme(scheme: 'orcid')
  if modified_by_orcid.present?
    json.modified_by do
      json.identifier modified_by_orcid.value
      json.type modified_by_orcid.identifier_format
    end
  end
end

json.reason version.belnet_reason
json.set! 'lifecycle-stage', version.current_lifecycle_stage_name
