# frozen_string_literal: true

# Belnet tasks to support any environment

namespace :belnet do
  ## namespace :users
  # First entry from Cyrille Bollu (04/2024), to be checked:
  # This task is designed to clean up users who have never had any activity after a certain period of time.
  # It checks for users who have never signed in and were created more than a year ago,
  # unlinks them from any existing plans, and deletes them from the database.

  namespace :users do
    desc 'Deletes users who never had any activity, after some time'
    task clean: :environment do
      User.where(last_sign_in_at: nil).find_each do |user|
        # Only consider users that have been created more than 1 year ago
        if user.created_at.year < (Date.today.year - 1)
          # Unlink user from any existing plan
          Role.where(user_id: user.id).destroy_all
          # Deletes user
          user.destroy
        end
      end
    end
  end

  ## namespace :org_stages
  # Belnet tasks to add stages to all orgs or a specific org by id
  # If usage is within docker terminal (bash) use:
  # Usage: bin/rails belnet:org_stages:create_global_stages["Stage Name"]
  # Usage: bin/rails belnet:org_stages:add_stages_to_org[62,"Stage Name"]
  #
  # If not using docker, use:
  # Usage: rails belnet:org_stages:add_stages_to_all
  # Usage: rails belnet:org_stages:add_stages_to_org

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

  ## namespace :org_validation_topics
  # This task is designed to give a certain org by id a set of validation topics
  # based on the code provided, so you execute the task with as parameter the topic
  # the task will then "parse" that code and create a description,
  # replacing the underscores with spaces and capitalizing the first letter of each word.
  # If usage is within docker terminal (bash) use:
  # IMPORTANT: dont use spaces between arguments!
  # Usage: bin/rails belnet:org_validation_topics:add_validation_topics_to_org[62,"ISO 27001"]
  #
  # If not using docker, use:
  # Usage: rails belnet:org_validation_topics:add_validation_topics_to_org[62,"ISO 27001"]

  namespace :org_validation_topics do
    desc 'Add validation topics to a specific org by ID'
    task :add_validation_topics_to_org, %i[org_id description] => :environment do |_, args|
      org_id = args[:org_id]
      input_description = args[:description]

      unless org_id && input_description
        puts 'ERROR: Both organization ID and Description must be provided.'
        puts "Usage: rails belnet:org_validation_topics:add_validation_topics_to_org[1, 'User Profile Status']"
        exit 1
      end

      org = Org.find_by(id: org_id)

      if org
        topic_code = input_description.parameterize(separator: '_').upcase

        puts "Input Description: '#{input_description}'"
        puts "Generated Code: '#{topic_code}'"

        begin
          org.belnet_validation_topics.find_or_create_by!(code: topic_code) do |t|
            t.description = input_description
          end
          puts "Validation Topic '#{topic_code}' successfully added/updated for #{org.name || org.id}."
        rescue ActiveRecord::RecordInvalid => e
          puts "[ERROR] Could not save topic: #{e.message}"
        end
      else
        puts "Organization with ID #{org_id} not found."
      end
    end
  end
end
