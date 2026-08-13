# frozen_string_literal: true

# locals: config (BelnetConfigLifecycleStage), org (Org or nil for global)

json.partial! 'api/belnet/v1/standard_response', total_items: 1

json.items [config] do |item|
  json.lifecycle_stages do
    json.partial! 'api/belnet/v1/configurations/config', config: item, org: org
  end
end
