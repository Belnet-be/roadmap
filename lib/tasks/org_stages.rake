# frozen_string_literal: true

# Belnet tasks to add stages to all managed orgs or a specific org by id
# If usage is within docker terminal (bash) use:
# Usage: bin/rails org_stages:add_stages_to_all
# Usage: bin/rails org_stages:add_stages_to_org
#
# If not using docker, use:
# Usage: rails org_stages:add_stages_to_all
# Usage: rails org_stages:add_stages_to_org

namespace :org_stages do
  def default_stages
    [
      { code: 'INITIAL_DRAFT', description: 'Initial Draft' },
      { code: 'WORKING_DRAFT', description: 'Working Draft' },
      { code: 'INTERMEDIATE', description: 'Intermediate' },
      { code: 'FINALIZED', description: 'Finalized' },
      { code: 'ARCHIVED', description: 'Archived' }
    ]
  end

  desc 'Add stages to all managed orgs'
  task add_stages_to_all: :environment do
    Org.where(managed: true).each do |org|
      default_stages.each do |stage|
        org.belnet_stages.find_or_create_by!(code: stage[:code]) do |s|
          s.description = stage[:description]
        end
      end
      puts "Added default stages to #{org.name || org.abbreviation || org.id}"
    end
  end

  desc 'Add stages to a specific org by ID'
  task :add_stages_to_org, [:org_id] => :environment do |_, args|
    org = Org.find_by(id: args[:org_id])

    if org
      puts "Adding stages to #{org.name || org.abbreviation || org.id}"
      default_stages.each do |stage|
        org.belnet_stages.find_or_create_by!(code: stage[:code]) do |s|
          s.description = stage[:description]
        end
      end
      puts 'Completed.'
    else
      puts "Organization with ID #{args[:org_id]} not found."
    end
  end
end
