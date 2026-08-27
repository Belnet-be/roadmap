# frozen_string_literal: true

# locals: config (BelnetConfigLifecycleStage), org (Org or nil for global)

json.partial! 'api/belnet/v1/standard_response', total_items: 1

json.items [config] do |item|
  json.lifecycle_stages do
    json.partial! 'api/belnet/v1/configurations/config',
                  config: item,
                  org: org,
                  current_list: org ? org.current_valid_belnet_stages : nil,
                  full_list: org ? org.all_belnet_stages : nil
  end
end
