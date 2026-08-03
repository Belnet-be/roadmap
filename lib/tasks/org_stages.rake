# frozen_string_literal: true

# Belnet tasks to add stages to all orgs or a specific org by id
# If usage is within docker terminal (bash) use:
# Usage: bin/rails org_stages:create_global_stages["Stage Name"]
# Usage: bin/rails org_stages:add_stages_to_org[62,"Stage Name"]
#
# If not using docker, use:
# Usage: rails org_stages:add_stages_to_all
# Usage: rails org_stages:add_stages_to_org

namespace :org_stages do
  desc 'Create global stages'
  task :create_global_stages, [:stage_name] => :environment do |_, args|
    BelnetStage.find_or_create_by!(name_id: args[:stage_name]) do |s|
      s.description = args[:stage_name]
    end
    puts "Added global stage: #{args[:stage_name]}"
  end

  desc 'Add stages to a specific org by ID'
  task :add_stages_to_org, %i[org_id stage_name] => :environment do |_, args|
    org = Org.find_by(id: args[:org_id])

    if org
      puts "Adding stages to #{org.name || org.abbreviation || org.id}"
      org.belnet_stages.find_or_create_by!(name_id: args[:stage_name]) do |s|
        s.description = args[:stage_name]
      end
      puts 'Completed.'
    else
      puts "Organization with ID #{args[:org_id]} not found."
    end
  end
end
