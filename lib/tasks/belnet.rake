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
  # Add a lifecycle stage name to an org's config, or the global config.
  # Examples (docker):
  #   bin/rails belnet:org_stages:create_global_stage["Working Draft"]
  #   bin/rails belnet:org_stages:add_stage_to_org[62,"Working Draft"]

  namespace :org_stages do
    desc 'Add a stage name to the GLOBAL lifecycle-stage config'
    task :create_global_stage, [:stage_name] => :environment do |_, args|
      add_global_name(BelnetConfigLifecycleStage, args[:stage_name])
      puts "Added global stage: #{args[:stage_name]}"
    end

    desc 'Add a stage name to a specific org by ID'
    task :add_stage_to_org, %i[org_id stage_name] => :environment do |_, args|
      with_org(args[:org_id]) do |org|
        org.add_lifecycle_stage!(args[:stage_name])
        puts "Added stage '#{args[:stage_name]}' to #{org_label(org)}."
      end
    end
  end

  ## namespace :org_validation_topics
  # Examples (docker):
  #   bin/rails belnet:org_validation_topics:create_global_topic["GDPR"]
  #   bin/rails belnet:org_validation_topics:add_topic_to_org[62,"GDPR"]

  namespace :org_validation_topics do
    desc 'Add a validation topic name to the GLOBAL config'
    task :create_global_topic, [:topic_name] => :environment do |_, args|
      add_global_name(BelnetConfigValidationTopic, args[:topic_name])
      puts "Added global validation topic: #{args[:topic_name]}"
    end

    desc 'Add a validation topic name to a specific org by ID'
    task :add_topic_to_org, %i[org_id topic_name] => :environment do |_, args|
      with_org(args[:org_id]) do |org|
        org.add_validation_topic!(args[:topic_name])
        puts "Added validation topic '#{args[:topic_name]}' to #{org_label(org)}."
      end
    end
  end

  ## namespace :org_validation_statuses
  # Examples (docker):
  #   bin/rails belnet:org_validation_statuses:create_global_status["Approved"]
  #   bin/rails belnet:org_validation_statuses:add_status_to_org[62,"Approved"]

  namespace :org_validation_statuses do
    desc 'Add a validation status name to the GLOBAL config'
    task :create_global_status, [:status_name] => :environment do |_, args|
      add_global_name(BelnetConfigValidationStatus, args[:status_name])
      puts "Added global validation status: #{args[:status_name]}"
    end

    desc 'Add a validation status name to a specific org by ID'
    task :add_status_to_org, %i[org_id status_name] => :environment do |_, args|
      with_org(args[:org_id]) do |org|
        org.add_validation_status!(args[:status_name])
        puts "Added validation status '#{args[:status_name]}' to #{org_label(org)}."
      end
    end
  end

  def with_org(org_id)
    if org_id.blank?
      puts 'ERROR: Organization ID is required.'
      return
    end

    org = Org.find_by(id: org_id)
    if org
      yield org
    else
      puts "Organization with ID #{org_id} not found."
    end
  end

  def org_label(org)
    org.name.presence || org.abbreviation.presence || org.id.to_s
  end

  def add_global_name(config_class, name)
    if name.blank?
      puts 'ERROR: A name is required.'
      return
    end

    config = config_class.find_or_initialize_by(org_id: nil) do |c|
      c.current_list_order = []
      c.full_list_order    = []
    end
    config.current_list_order = (config.current_list_order || []) | [name]
    config.full_list_order    = (config.full_list_order    || []) | [name]
    config.save!
  end
end
