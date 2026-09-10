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
  # Manage lifecycle stage names on an org's config or the GLOBAL config: adds insert at a
  # 1-based position into both lists, deletes remove from the current list only.
  # Examples (docker):
  #   bin/rails belnet:org_stages:create_global_stage["Working Draft"]
  #   # First number param is the index of the current list (the list that is used in dropdowns),
  #   # second number param is the index of the full list (the list that preserves historical names for audits)
  #   bin/rails belnet:org_stages:add_stage_to_org[62,"Working Draft",2,3]
  #   bin/rails belnet:org_stages:delete_stage_from_org[62,"Working Draft"]
  #   bin/rails belnet:org_stages:list[62]
  #   bin/rails belnet:org_stages:list

  namespace :org_stages do
    desc 'Add a stage name to the GLOBAL lifecycle-stage config'
    task :create_global_stage, [:stage_name] => :environment do |_, args|
      add_global_name(BelnetConfigLifecycleStage, args[:stage_name])
      puts "Added global stage: #{args[:stage_name]}"
    end

    desc 'Add a stage name to a specific org by ID at current and full 1-based positions'
    task :add_stage_to_org, %i[org_id stage_name current_position full_position] => :environment do |_, args|
      with_org_and_positions(args, BelnetConfigLifecycleStage) do |org, current_position, full_position|
        org.add_lifecycle_stage!(args[:stage_name], current_position: current_position, full_position: full_position)
        puts "Added stage '#{args[:stage_name]}' to #{org_label(org)} at current position #{current_position}, full position #{full_position}."
      end
    end

    desc "Remove a stage (by name_id) from an org's CURRENT list; full list is preserved"
    task :delete_stage_from_org, %i[org_id name_id] => :environment do |_, args|
      with_org_and_name_id(args) do |org, name_id|
        org.remove_lifecycle_stage!(name_id)
        puts "Removed stage '#{name_id}' from current list of #{org_label(org)} (full list preserved)."
      end
    end

    desc 'List the lifecycle stages for an org (blank org_id => GLOBAL) with 1-based indices'
    task :list, [:org_id] => :environment do |_, args|
      print_config_lists(BelnetConfigLifecycleStage, args[:org_id], kind: 'lifecycle-stage')
    end
  end

  ## namespace :org_validation_topics
  # Same semantics as :org_stages, for validation topic names.
  # Examples (docker):
  #   bin/rails belnet:org_validation_topics:create_global_topic["GDPR"]
  #   # First number param is the index of the current list (the list that is used in dropdowns),
  #   # second number param is the index of the full list (the list that preserves historical names for audits)
  #   bin/rails belnet:org_validation_topics:add_topic_to_org[62,"GDPR",1,2]
  #   bin/rails belnet:org_validation_topics:delete_topic_from_org[62,"GDPR"]
  #   bin/rails belnet:org_validation_topics:list[62]
  #   bin/rails belnet:org_validation_topics:list

  namespace :org_validation_topics do
    desc 'Add a validation topic name to the GLOBAL config'
    task :create_global_topic, [:topic_name] => :environment do |_, args|
      add_global_name(BelnetConfigValidationTopic, args[:topic_name])
      puts "Added global validation topic: #{args[:topic_name]}"
    end

    desc 'Add a validation topic name to a specific org by ID at current and full 1-based positions'
    task :add_topic_to_org, %i[org_id topic_name current_position full_position] => :environment do |_, args|
      with_org_and_positions(args, BelnetConfigValidationTopic) do |org, current_position, full_position|
        org.add_validation_topic!(args[:topic_name], current_position: current_position, full_position: full_position)
        puts "Added validation topic '#{args[:topic_name]}' to #{org_label(org)} at current position #{current_position}, full position #{full_position}."
      end
    end

    desc "Remove a validation topic (by name_id) from an org's CURRENT list; full list is preserved"
    task :delete_topic_from_org, %i[org_id name_id] => :environment do |_, args|
      with_org_and_name_id(args) do |org, name_id|
        org.remove_validation_topic!(name_id)
        puts "Removed validation topic '#{name_id}' from current list of #{org_label(org)} (full list preserved)."
      end
    end

    desc 'List the validation topics for an org (blank org_id => GLOBAL) with 1-based indices'
    task :list, [:org_id] => :environment do |_, args|
      print_config_lists(BelnetConfigValidationTopic, args[:org_id], kind: 'validation-topic')
    end
  end

  ## namespace :org_validation_statuses
  # Same semantics as :org_stages, for validation status names.
  # Examples (docker):
  #   bin/rails belnet:org_validation_statuses:create_global_status["Approved"]
  #   # First number param is the index of the current list (the list that is used in dropdowns),
  #   # second number param is the index of the full list (the list that preserves historical names for audits)
  #   bin/rails belnet:org_validation_statuses:add_status_to_org[62,"Approved",3,4]
  #   bin/rails belnet:org_validation_statuses:delete_status_from_org[62,"Approved"]
  #   bin/rails belnet:org_validation_statuses:list[62]
  #   bin/rails belnet:org_validation_statuses:list

  namespace :org_validation_statuses do
    desc 'Add a validation status name to the GLOBAL config'
    task :create_global_status, [:status_name] => :environment do |_, args|
      add_global_name(BelnetConfigValidationStatus, args[:status_name])
      puts "Added global validation status: #{args[:status_name]}"
    end

    desc 'Add a validation status name to a specific org by ID at current and full 1-based positions'
    task :add_status_to_org, %i[org_id status_name current_position full_position] => :environment do |_, args|
      with_org_and_positions(args, BelnetConfigValidationStatus) do |org, current_position, full_position|
        org.add_validation_status!(args[:status_name], current_position: current_position, full_position: full_position)
        puts "Added validation status '#{args[:status_name]}' to #{org_label(org)} at current position #{current_position}, full position #{full_position}."
      end
    end

    desc "Remove a validation status (by name_id) from an org's CURRENT list; full list is preserved"
    task :delete_status_from_org, %i[org_id name_id] => :environment do |_, args|
      with_org_and_name_id(args) do |org, name_id|
        org.remove_validation_status!(name_id)
        puts "Removed validation status '#{name_id}' from current list of #{org_label(org)} (full list preserved)."
      end
    end

    desc 'List the validation statuses for an org (blank org_id => GLOBAL) with 1-based indices'
    task :list, [:org_id] => :environment do |_, args|
      print_config_lists(BelnetConfigValidationStatus, args[:org_id], kind: 'validation-status')
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

  # Wraps add-to-org tasks: resolves the org, validates positions and reports model errors.
  def with_org_and_positions(args, config_class)
    if args[:current_position].blank? || args[:full_position].blank?
      puts 'ERROR: Current and full positions (1-based) are required for org-level adds.'
      return
    end
    current_position = Integer(args[:current_position])
    full_position = Integer(args[:full_position])

    with_org(args[:org_id]) do |org|
      unless config_class.exists?(org_id: org.id)
        global = config_class.find_by(org_id: nil)
        if global
          puts "Note: org #{org_label(org)} has no row of its own yet; " \
               "seeding it from the GLOBAL row (#{global.current_list_order.length} " \
               'current entries) before inserting.'
        end
      end

      yield org, current_position, full_position
    end
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  # Wraps delete-from-org tasks: resolves the org, validates name_id and reports model errors.
  def with_org_and_name_id(args)
    if args[:name_id].blank?
      puts 'ERROR: name_id is required.'
      return
    end

    with_org(args[:org_id]) { |org| yield org, args[:name_id] }
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  def org_label(org)
    org.name.presence || org.abbreviation.presence || org.id.to_s
  end

  # Print the current and full list of a config row, one line each.
  def print_config_lists(config_class, org_id, kind:)
    scope_desc, config = resolve_config_row(config_class, org_id, kind: kind)
    return unless config

    puts "Current list (#{scope_desc}): #{indexed_names(config.current_list_order)}"
    puts "Full list (#{scope_desc}): #{indexed_names(config.full_list_order)}"
  end

  # Returns [scope_desc, config_row] for the given org_id: the org's own row, else the GLOBAL fallback.
  def resolve_config_row(config_class, org_id, kind:)
    if org_id.blank?
      config = config_class.find_by(org_id: nil)
      unless config
        puts "No #{kind} config found for GLOBAL."
        return [nil, nil]
      end
      return ['GLOBAL', config]
    end

    org = Org.find_by(id: org_id)
    unless org
      puts "Organization with ID #{org_id} not found."
      return [nil, nil]
    end

    own = config_class.find_by(org_id: org.id)
    return ["org #{org_label(org)} (id=#{org.id})", own] if own

    global = config_class.find_by(org_id: nil)
    unless global
      puts "No #{kind} config found for org #{org_label(org)} (id=#{org.id}) and no GLOBAL fallback exists."
      return [nil, nil]
    end

    ["GLOBAL (fallback: org #{org_label(org)} (id=#{org.id}) has no row of its own)", global]
  end

  def indexed_names(list)
    list ||= []
    return '(empty)' if list.empty?

    list.each_with_index.map { |name, i| "#{i + 1}. '#{name}'" }.join(', ')
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
