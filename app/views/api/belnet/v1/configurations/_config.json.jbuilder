# frozen_string_literal: true

# locals: config (a belnet config row), org (Org or nil for the global row)

json.modified config.updated_at.utc.iso8601

json.organization do
  if org
    json.org_id           org.id
    json.org_name         org.name
    json.org_abbreviation org.abbreviation
  else
    # The global fallback row: use sentinel values matching the public spec.
    json.org_id           0
    json.org_name         _('All organizations in DMPOnline')
    json.org_abbreviation _('All')
  end
end

json.current_list do
  json.enum(config.current_list_order || [])
end

json.full_list do
  json.enum(config.full_list_order || [])
end
