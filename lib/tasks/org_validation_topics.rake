# frozen_string_literal: true

# This task is designed to give a certain org by id a set of validation topics
# based on the code provided, so you execute the task with as parameter the topic
# the task will then "parse" that code and create a description,
# replacing the underscores with spaces and capitalizing the first letter of each word.
# If usage is within docker terminal (bash) use:
# IMPORTANT: dont use spaces between arguments!
# Usage: bin/rails org_validation_topics:add_validation_topics_to_org[62,"ISO 27001"]
#
# If not using docker, use:
# Usage: rails org_validation_topics:add_validation_topics_to_org[62,"ISO 27001"]

namespace :org_validation_topics do
  desc 'Add validation topics to a specific org by ID'
  task :add_validation_topics_to_org, %i[org_id description] => :environment do |_, args|
    org_id = args[:org_id]
    input_description = args[:description]

    unless org_id && input_description
      puts 'ERROR: Both organization ID and Description must be provided.'
      puts "Usage: rails org_validation_topics:add_validation_topics_to_org[1, 'User Profile Status']"
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
