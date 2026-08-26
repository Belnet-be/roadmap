# frozen_string_literal: true

# locals: plan

json.dmp_id do
  json.identifier "#{request.base_url}/api/belnet-v1/plans/#{plan.id}"
  json.type 'url'
end
