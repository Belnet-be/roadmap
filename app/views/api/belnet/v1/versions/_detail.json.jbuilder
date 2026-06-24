# frozen_string_literal: true

# locals: version

json.partial! 'api/belnet/v1/versions/summary', version: version
json.reasonForChange version.belnet_reason
json.lifecycleStageTypeId version.belnet_stage_id
json.createdBy version.belnet_created_by
