# frozen_string_literal: true

# locals: config (BelnetConfigValidationTopic), org (Org or nil for global)

json.partial! 'api/belnet/v1/standard_response', total_items: 1

json.items [config] do |item|
  json.validation_topics do
    json.partial! 'api/belnet/v1/configurations/config', config: item, org: org
  end
end
