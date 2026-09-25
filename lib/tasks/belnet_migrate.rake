# frozen_string_literal: true

# Belnet tasks to support the migration in production for the Belnet DMPonline release 5.0.0
# Usage: bin/rails belnet_migrate:setup_default_configs

namespace :belnet_migrate do
  task setup_default_configs: :environment do
    puts 'Setup default configs for lifecycle stages, validation statuses and validation topics'
    unless BelnetConfigLifecycleStage.exists?(id: 1)
      puts 'Creating default lifecycle stages'
      lifecycle_stages1 = BelnetConfigLifecycleStage.new
      # Because JSON strings require double quotes, we need to disable the rubocop rule for string literals here
      # rubocop:disable Style/StringLiterals
      lifecycle_stages1.current_list_order = [
        "Initial Draft",
        "Working Draft",
        "Intermediate",
        "Finalized",
        "Archived"
      ]
      lifecycle_stages1.full_list_order = [
        "Initial Draft",
        "Working Draft",
        "Intermediate",
        "Finalized",
        "Archived"
      ]
      # rubocop:enable Style/StringLiterals
      lifecycle_stages1.save!
      puts 'Created default lifecycle stages'
    end
    unless BelnetConfigValidationStatus.exists?(id: 1)
      puts 'Creating default validation statuses'
      validation_statuses1 = BelnetConfigValidationStatus.new
      # Because JSON strings require double quotes, we need to disable the rubocop rule for string literals here
      # rubocop:disable Style/StringLiterals
      validation_statuses1.current_list_order = [
        "Pending Review",
        "Approved",
        "Denied",
        "Rework Needed"
      ]
      validation_statuses1.full_list_order = [
        "Pending Review",
        "Approved",
        "Denied",
        "Rework Needed"
      ]
      # rubocop:enable Style/StringLiterals
      validation_statuses1.save!
      puts 'Created default validation statuses'
    end
    unless BelnetConfigValidationTopic.exists?(id: 1)
      puts 'Creating default validation topics'
      validation_topics1 = BelnetConfigValidationTopic.new
      # Because JSON strings require double quotes, we need to disable the rubocop rule for string literals here
      # rubocop:disable Style/StringLiterals
      validation_topics1.current_list_order = [
        "General",
        "FAIR",
        "GDPR",
        "Data security"
      ]
      validation_topics1.full_list_order = [
        "General",
        "FAIR",
        "GDPR",
        "Data security"
      ]
      # rubocop:enable Style/StringLiterals
      validation_topics1.save!
      puts 'Created default validation topics'
    end
  end
end
