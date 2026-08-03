# frozen_string_literal: true

# locals: version

json.partial! 'api/belnet/v1/versions/summary', version: version
json.reason_for_change version.belnet_reason
json.set! 'lifecycle-stage', version.current_lifecycle_stage_name
json.lifecycle_stage_type_id version.current_belnet_stage&.id
json.created_by version.belnet_created_by
