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
  # 1-based position into both lists (a global add propagates to every org row),
  # deletes remove from the current list only (a global delete also clears the name from
  # every org's current list), moves reposition without adding or removing.
  # Examples (docker):
  #   bin/rails belnet:org_stages:create_global_stage["Working Draft",2,3]
  #   # First number param is the index of the current list (the list that is used in dropdowns),
  #   # second number param is the index of the full list (the list that preserves historical names for audits)
  #   bin/rails belnet:org_stages:add_stage_to_org[62,"Working Draft",2,3]
  #   bin/rails belnet:org_stages:delete_global_stage["Working Draft"]
  #   bin/rails belnet:org_stages:delete_stage_from_org[62,"Working Draft"]
  #   bin/rails belnet:org_stages:move_stage_in_org[62,"Working Draft",2,3]
  #   # Leave a position blank to keep that list as-is:
  #   bin/rails belnet:org_stages:move_stage_in_org[62,"Working Draft",,3]
  #   bin/rails belnet:org_stages:list[62]
  #   bin/rails belnet:org_stages:list

  namespace :org_stages do
    desc 'Add a stage name to the GLOBAL config at current and full 1-based positions'
    task :create_global_stage, %i[stage_name current_position full_position] => :environment do |_, args|
      with_positions(args) do |current_position, full_position|
        orgs = add_global_name(BelnetConfigLifecycleStage, args[:stage_name], current_position, full_position)
        puts "Added global stage '#{args[:stage_name]}' at current position #{current_position}, " \
             "full position #{full_position} (propagated to #{orgs} org row(s))."
      end
    end

    desc 'Add a stage name to a specific org by ID at current and full 1-based positions'
    task :add_stage_to_org, %i[org_id stage_name current_position full_position] => :environment do |_, args|
      with_org_and_positions(args, BelnetConfigLifecycleStage) do |org, current_position, full_position|
        org.add_lifecycle_stage!(args[:stage_name], current_position: current_position, full_position: full_position)
        puts "Added stage '#{args[:stage_name]}' to #{org_label(org)} at current position #{current_position}, full position #{full_position}."
      end
    end

    desc "Remove a stage (by name_id) from the GLOBAL and every org's CURRENT list; full lists preserved"
    task :delete_global_stage, [:name_id] => :environment do |_, args|
      with_name_id(args) do |name_id|
        orgs = remove_global_name(BelnetConfigLifecycleStage, name_id)
        puts "Removed global stage '#{name_id}' from the GLOBAL current list " \
             "(and from #{orgs} org current list(s); full lists preserved)."
      end
    end

    desc "Remove a stage (by name_id) from an org's CURRENT list; full list is preserved"
    task :delete_stage_from_org, %i[org_id name_id] => :environment do |_, args|
      with_org_and_name_id(args) do |org, name_id|
        org.remove_lifecycle_stage!(name_id)
        puts "Removed stage '#{name_id}' from current list of #{org_label(org)} (full list preserved)."
      end
    end

    desc "Move a stage inside an org's lists (blank position leaves that list as-is)"
    task :move_stage_in_org, %i[org_id name_id current_position full_position] => :environment do |_, args|
      with_move_positions(args) do |current_position, full_position|
        with_org(args[:org_id]) do |org|
          move_org_name(BelnetConfigLifecycleStage, org, args[:name_id], current_position, full_position)
          puts "Moved stage '#{args[:name_id]}' for #{org_label(org)} " \
               "#{moved_to(current_position, full_position)}."
        end
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
  #   bin/rails belnet:org_validation_topics:create_global_topic["GDPR",1,2]
  #   # First number param is the index of the current list (the list that is used in dropdowns),
  #   # second number param is the index of the full list (the list that preserves historical names for audits)
  #   bin/rails belnet:org_validation_topics:add_topic_to_org[62,"GDPR",1,2]
  #   bin/rails belnet:org_validation_topics:delete_global_topic["GDPR"]
  #   bin/rails belnet:org_validation_topics:delete_topic_from_org[62,"GDPR"]
  #   bin/rails belnet:org_validation_topics:move_topic_in_org[62,"GDPR",1,2]
  #   bin/rails belnet:org_validation_topics:list[62]
  #   bin/rails belnet:org_validation_topics:list

  namespace :org_validation_topics do
    desc 'Add a validation topic name to the GLOBAL config at current and full 1-based positions'
    task :create_global_topic, %i[topic_name current_position full_position] => :environment do |_, args|
      with_positions(args) do |current_position, full_position|
        orgs = add_global_name(BelnetConfigValidationTopic, args[:topic_name], current_position, full_position)
        puts "Added global validation topic '#{args[:topic_name]}' at current position #{current_position}, " \
             "full position #{full_position} (propagated to #{orgs} org row(s))."
      end
    end

    desc 'Add a validation topic name to a specific org by ID at current and full 1-based positions'
    task :add_topic_to_org, %i[org_id topic_name current_position full_position] => :environment do |_, args|
      with_org_and_positions(args, BelnetConfigValidationTopic) do |org, current_position, full_position|
        org.add_validation_topic!(args[:topic_name], current_position: current_position, full_position: full_position)
        puts "Added validation topic '#{args[:topic_name]}' to #{org_label(org)} at current position #{current_position}, full position #{full_position}."
      end
    end

    desc "Remove a validation topic (by name_id) from the GLOBAL and every org's CURRENT list; full lists preserved"
    task :delete_global_topic, [:name_id] => :environment do |_, args|
      with_name_id(args) do |name_id|
        orgs = remove_global_name(BelnetConfigValidationTopic, name_id)
        puts "Removed global validation topic '#{name_id}' from the GLOBAL current list " \
             "(and from #{orgs} org current list(s); full lists preserved)."
      end
    end

    desc "Remove a validation topic (by name_id) from an org's CURRENT list; full list is preserved"
    task :delete_topic_from_org, %i[org_id name_id] => :environment do |_, args|
      with_org_and_name_id(args) do |org, name_id|
        org.remove_validation_topic!(name_id)
        puts "Removed validation topic '#{name_id}' from current list of #{org_label(org)} (full list preserved)."
      end
    end

    desc "Move a validation topic inside an org's lists (blank position leaves that list as-is)"
    task :move_topic_in_org, %i[org_id name_id current_position full_position] => :environment do |_, args|
      with_move_positions(args) do |current_position, full_position|
        with_org(args[:org_id]) do |org|
          move_org_name(BelnetConfigValidationTopic, org, args[:name_id], current_position, full_position)
          puts "Moved validation topic '#{args[:name_id]}' for #{org_label(org)} " \
               "#{moved_to(current_position, full_position)}."
        end
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
  #   bin/rails belnet:org_validation_statuses:create_global_status["Approved",3,4]
  #   # First number param is the index of the current list (the list that is used in dropdowns),
  #   # second number param is the index of the full list (the list that preserves historical names for audits)
  #   bin/rails belnet:org_validation_statuses:add_status_to_org[62,"Approved",3,4]
  #   bin/rails belnet:org_validation_statuses:delete_global_status["Approved"]
  #   bin/rails belnet:org_validation_statuses:delete_status_from_org[62,"Approved"]
  #   bin/rails belnet:org_validation_statuses:move_status_in_org[62,"Approved",3,4]
  #   bin/rails belnet:org_validation_statuses:list[62]
  #   bin/rails belnet:org_validation_statuses:list

  namespace :org_validation_statuses do
    desc 'Add a validation status name to the GLOBAL config at current and full 1-based positions'
    task :create_global_status, %i[status_name current_position full_position] => :environment do |_, args|
      with_positions(args) do |current_position, full_position|
        orgs = add_global_name(BelnetConfigValidationStatus, args[:status_name], current_position, full_position)
        puts "Added global validation status '#{args[:status_name]}' at current position #{current_position}, " \
             "full position #{full_position} (propagated to #{orgs} org row(s))."
      end
    end

    desc 'Add a validation status name to a specific org by ID at current and full 1-based positions'
    task :add_status_to_org, %i[org_id status_name current_position full_position] => :environment do |_, args|
      with_org_and_positions(args, BelnetConfigValidationStatus) do |org, current_position, full_position|
        org.add_validation_status!(args[:status_name], current_position: current_position, full_position: full_position)
        puts "Added validation status '#{args[:status_name]}' to #{org_label(org)} at current position #{current_position}, full position #{full_position}."
      end
    end

    desc "Remove a validation status (by name_id) from the GLOBAL and every org's CURRENT list; full lists preserved"
    task :delete_global_status, [:name_id] => :environment do |_, args|
      with_name_id(args) do |name_id|
        orgs = remove_global_name(BelnetConfigValidationStatus, name_id)
        puts "Removed global validation status '#{name_id}' from the GLOBAL current list " \
             "(and from #{orgs} org current list(s); full lists preserved)."
      end
    end

    desc "Remove a validation status (by name_id) from an org's CURRENT list; full list is preserved"
    task :delete_status_from_org, %i[org_id name_id] => :environment do |_, args|
      with_org_and_name_id(args) do |org, name_id|
        org.remove_validation_status!(name_id)
        puts "Removed validation status '#{name_id}' from current list of #{org_label(org)} (full list preserved)."
      end
    end

    desc "Move a validation status inside an org's lists (blank position leaves that list as-is)"
    task :move_status_in_org, %i[org_id name_id current_position full_position] => :environment do |_, args|
      with_move_positions(args) do |current_position, full_position|
        with_org(args[:org_id]) do |org|
          move_org_name(BelnetConfigValidationStatus, org, args[:name_id], current_position, full_position)
          puts "Moved validation status '#{args[:name_id]}' for #{org_label(org)} " \
               "#{moved_to(current_position, full_position)}."
        end
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

  # Wraps add tasks: validates the two 1-based positions and reports model errors.
  def with_positions(args)
    if args[:current_position].blank? || args[:full_position].blank?
      puts 'ERROR: Current and full positions (1-based) are required for adds.'
      return
    end

    yield Integer(args[:current_position]), Integer(args[:full_position])
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  # Wraps move tasks: at least one 1-based position is required, a blank one leaves that list as-is.
  def with_move_positions(args)
    current_position = args[:current_position].presence
    full_position = args[:full_position].presence
    if current_position.nil? && full_position.nil?
      puts 'ERROR: A current and/or full position (1-based) is required for moves.'
      return
    end

    yield(current_position && Integer(current_position), full_position && Integer(full_position))
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  # Wraps add-to-org tasks: validates positions, resolves the org and reports model errors.
  def with_org_and_positions(args, config_class)
    with_positions(args) do |current_position, full_position|
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
    end
  end

  # Wraps delete tasks: validates name_id and reports model errors.
  def with_name_id(args)
    if args[:name_id].blank?
      puts 'ERROR: name_id is required.'
      return
    end

    yield args[:name_id]
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  # Wraps delete-from-org tasks: validates name_id, resolves the org and reports model errors.
  def with_org_and_name_id(args)
    with_name_id(args) { |name_id| with_org(args[:org_id]) { |org| yield org, name_id } }
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
    print_order_drift(config_class, config)
  end

  # Warn when an org row orders its GLOBAL-shared entries differently than GLOBAL does.
  def print_order_drift(config_class, config)
    return if config.org_id.nil?

    global = config_class.find_by(org_id: nil)
    return unless global

    notes = [order_drift_note(config.current_list_order, global.current_list_order, 'Current list'),
             order_drift_note(config.full_list_order, global.full_list_order, 'Full list')].compact
    puts notes
  end

  # Returns a note when the entries shared with GLOBAL sit in a different relative order.
  def order_drift_note(list, global_list, label)
    list = (list || []).map(&:to_s)
    global_list = (global_list || []).map(&:to_s)
    shared = list & global_list
    expected = global_list & shared
    return nil if shared == expected

    "Note: #{label} orders GLOBAL entries differently (GLOBAL order: #{indexed_names(expected)})."
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

  # Insert +name+ into the GLOBAL row at the given 1-based positions and into every
  # org row as well, so a global entry always ends up active for every org — including
  # a name that was globally deleted earlier and is being re-added now, which the
  # GLOBAL full list still remembers. Returns the number of org rows updated.
  def add_global_name(config_class, name, current_position, full_position)
    raise ArgumentError, 'A name is required' if name.blank?

    global = config_class.find_or_initialize_by(org_id: nil) do |c|
      c.current_list_order = []
      c.full_list_order    = []
    end
    global.current_list_order = insert_at(global.current_list_order, name, current_position, 'current_position')
    global.full_list_order    = insert_at(global.full_list_order, name, full_position, 'full_position')
    global.save!

    propagate_to_orgs(config_class, name, global)
  end

  # Add +name+ to every org row that is missing it from either list, keeping each org's
  # own ordering; rows that already carry it in both lists are left untouched, so no
  # duplicates and no reordering. Returns the number of rows actually updated.
  def propagate_to_orgs(config_class, name, global)
    rows = config_class.where.not(org_id: nil).reject do |row|
      (row.current_list_order || []).map(&:to_s).include?(name) &&
        (row.full_list_order || []).map(&:to_s).include?(name)
    end
    rows.each do |row|
      row.current_list_order = insert_near(row.current_list_order, name, global.current_list_order)
      row.full_list_order    = insert_near(row.full_list_order, name, global.full_list_order)
      row.save!
    end
    rows.length
  end

  # Remove +name+ from the GLOBAL row's current list and from every org row's current
  # list, so it stops showing up in dropdowns everywhere; full lists are never touched,
  # so historical references keep resolving. Returns the number of org rows updated.
  def remove_global_name(config_class, name_id)
    name = name_id.to_s
    global = config_class.find_by(org_id: nil)
    raise ArgumentError, 'No GLOBAL row exists; nothing to remove' unless global

    current = (global.current_list_order || []).map(&:to_s)
    raise ArgumentError, "'#{name}' is not in the GLOBAL current list; nothing to remove" unless current.include?(name)

    global.current_list_order = current.reject { |n| n == name }
    global.save!

    remove_from_orgs(config_class, name)
  end

  # Drop +name+ from the current list of every org row that still carries it; returns the row count.
  def remove_from_orgs(config_class, name)
    rows = config_class.where.not(org_id: nil).select do |row|
      (row.current_list_order || []).map(&:to_s).include?(name)
    end
    rows.each do |row|
      row.current_list_order = (row.current_list_order || []).map(&:to_s).reject { |n| n == name }
      row.save!
    end
    rows.length
  end

  # Returns +list+ with +name+ inserted at the given 1-based position (unchanged when present).
  def insert_at(list, name, position, label)
    list = (list || []).map(&:to_s)
    return list if list.include?(name)

    index = position - 1
    if index.negative? || index > list.length
      raise ArgumentError, "#{label} must be between 1 and #{list.length + 1} (got #{position})"
    end

    list.insert(index, name)
  end

  # Returns +list+ with +name+ inserted just after the entry that precedes it in
  # +global_list+, or appended when that entry is absent (unchanged when present).
  def insert_near(list, name, global_list)
    list = (list || []).map(&:to_s)
    return list if list.include?(name)

    global_index = global_list.index(name) || global_list.length
    return list.unshift(name) if global_index.zero?

    anchor_index = list.index(global_list[global_index - 1])
    anchor_index ? list.insert(anchor_index + 1, name) : list.push(name)
  end

  # Reposition a name in an org's row, seeding that row from GLOBAL when it has none yet.
  def move_org_name(config_class, org, name_id, current_position, full_position)
    config = config_class.find_or_initialize_by(org_id: org.id)
    if config.new_record?
      global = config_class.find_by(org_id: nil)
      config.current_list_order = (global&.current_list_order || []).dup
      config.full_list_order    = (global&.full_list_order    || []).dup
    end

    move_name!(config, name_id, current_position, full_position)
  end

  # Move an existing name to new 1-based positions; a move never adds or removes a name.
  def move_name!(config, name_id, current_position, full_position)
    name = name_id.to_s
    raise ArgumentError, 'name_id is required' if name.blank?

    full = (config.full_list_order || []).map(&:to_s)
    raise ArgumentError, "'#{name}' is not in the full list; nothing to move" unless full.include?(name)

    config.current_list_order = moved_current_list(config, name, current_position) if current_position
    config.full_list_order    = reposition(full, name, full_position, 'full_position') if full_position
    config.save!
  end

  # Returns the current list with +name+ moved, refusing to re-activate a retired name.
  def moved_current_list(config, name, position)
    current = (config.current_list_order || []).map(&:to_s)
    unless current.include?(name)
      raise ArgumentError,
            "'#{name}' is not in the current list; use the add task to re-activate it"
    end

    reposition(current, name, position, 'current_position')
  end

  # Returns +list+ with the already-present +name+ moved to the given 1-based position.
  def reposition(list, name, position, label)
    index = position - 1
    if index.negative? || index >= list.length
      raise ArgumentError, "#{label} must be between 1 and #{list.length} (got #{position})"
    end

    list.reject { |n| n == name }.insert(index, name)
  end

  # Describes which lists a move touched, for task output.
  def moved_to(current_position, full_position)
    parts = []
    parts << "to current position #{current_position}" if current_position
    parts << "to full position #{full_position}" if full_position
    parts.join(', ')
  end
end
