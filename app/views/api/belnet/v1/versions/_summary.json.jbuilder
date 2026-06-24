# frozen_string_literal: true

# locals: version

json.versionId version.id
json.versionNumber version.belnet_version
json.createdAt version.created_at.to_formatted_s(:iso8601)
