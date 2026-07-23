# frozen_string_literal: true

# locals: version

json.version_id version.id
json.version_number version.belnet_version
json.created_at version.created_at.to_formatted_s(:iso8601)
