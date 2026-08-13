# frozen_string_literal: true

# locals: validation

json.id validation.id
json.dmp_version_number validation.validated_plan&.belnet_version
json.created validation.created_at.utc.iso8601

json.modified validation.reviewed_at.utc.iso8601 if validation.reviewed_at.present?

created_by_orcid = validation.requested_by&.identifier_for_scheme(scheme: 'orcid')
if created_by_orcid.present?
  json.created_by do
    json.identifier created_by_orcid.value
    json.type created_by_orcid.identifier_format
  end
end

if validation.reviewed_at.present?
  modified_by_orcid = validation.reviewed_by&.identifier_for_scheme(scheme: 'orcid')
  if modified_by_orcid.present?
    json.modified_by do
      json.identifier modified_by_orcid.value
      json.type modified_by_orcid.identifier_format
    end
  end
end

# Topic and status are stored as name strings on the validation row.
json.topic validation.validation_topic
json.status validation.validation_status.presence || _('Pending Review')

json.rationale validation.rationale if validation.rationale.present?
json.conditions validation.conditions if validation.conditions.present?
