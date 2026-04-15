# frozen_string_literal: true

json.partial! 'api/belnet/v1/standard_response'

json.items []
json.errors @payload[:errors]
