# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_06_22_130102) do
  create_schema "roadmap_development"

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "annotations", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.integer "org_id"
    t.text "text"
    t.integer "type", default: 0, null: false
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.string "versionable_id", limit: 36
    t.index ["org_id"], name: "idx_132088846_fk_rails_aca7521f72"
    t.index ["question_id"], name: "idx_132088846_index_annotations_on_question_id"
    t.index ["versionable_id"], name: "idx_132088846_index_annotations_on_versionable_id"
  end

  create_table "answers", id: :serial, force: :cascade do |t|
    t.text "text"
    t.integer "plan_id"
    t.integer "user_id"
    t.integer "question_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "lock_version", default: 0
    t.index ["plan_id"], name: "idx_132088854_index_answers_on_plan_id"
    t.index ["question_id"], name: "idx_132088854_index_answers_on_question_id"
    t.index ["user_id"], name: "idx_132088854_fk_rails_584be190c2"
  end

  create_table "answers_question_options", id: false, force: :cascade do |t|
    t.integer "answer_id", null: false
    t.integer "question_option_id", null: false
    t.index ["answer_id"], name: "idx_132088861_index_answers_question_options_on_answer_id"
    t.index ["question_option_id"], name: "idx_132088861_fk_rails_01ba00b569"
  end

  create_table "api_clients", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "description", limit: 255
    t.string "homepage", limit: 255
    t.string "contact_name", limit: 255
    t.string "contact_email", limit: 255, null: false
    t.string "client_id", limit: 255, null: false
    t.string "client_secret", limit: 255, null: false
    t.timestamptz "last_access"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.integer "org_id"
    t.index ["name"], name: "idx_132088865_index_api_clients_on_name"
  end

  create_table "belnet_config_lifecycle_stages", force: :cascade do |t|
    t.integer "org_id"
    t.json "current_list_order"
    t.json "full_list_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["org_id"], name: "index_belnet_config_lifecycle_stages_on_org_id"
  end

  create_table "belnet_config_validation_statuses", force: :cascade do |t|
    t.integer "org_id"
    t.json "current_list_order"
    t.json "full_list_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["org_id"], name: "index_belnet_config_validation_statuses_on_org_id"
  end

  create_table "belnet_config_validation_topics", force: :cascade do |t|
    t.integer "org_id"
    t.json "current_list_order"
    t.json "full_list_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["org_id"], name: "index_belnet_config_validation_topics_on_org_id"
  end

  create_table "belnet_editable_plan_metadata", force: :cascade do |t|
    t.integer "plan_id", null: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.string "lifecycle_stage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_belnet_editable_plan_metadata_on_created_by_id"
    t.index ["plan_id"], name: "index_belnet_editable_plan_metadata_on_plan_id"
    t.index ["updated_by_id"], name: "index_belnet_editable_plan_metadata_on_updated_by_id"
  end

  create_table "belnet_plan_version_metadata", force: :cascade do |t|
    t.integer "plan_id", null: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.integer "editable_plan_id"
    t.integer "versioned_plan_id"
    t.text "reason"
    t.string "lifecycle_stage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_belnet_plan_version_metadata_on_created_by_id"
    t.index ["editable_plan_id"], name: "index_belnet_plan_version_metadata_on_editable_plan_id"
    t.index ["plan_id"], name: "index_belnet_plan_version_metadata_on_plan_id"
    t.index ["updated_by_id"], name: "index_belnet_plan_version_metadata_on_updated_by_id"
    t.index ["versioned_plan_id"], name: "index_belnet_plan_version_metadata_on_versioned_plan_id"
  end

  create_table "belnet_stage_histories", force: :cascade do |t|
    t.string "motivation"
    t.string "lifecycle_stage"
    t.integer "plan_id", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_belnet_stage_histories_on_plan_id"
    t.index ["user_id"], name: "index_belnet_stage_histories_on_user_id"
  end

  create_table "belnet_validations", force: :cascade do |t|
    t.integer "plan_id", null: false
    t.integer "validated_plan_id", null: false
    t.string "validation_topic", null: false
    t.string "validation_status"
    t.text "rationale"
    t.text "conditions"
    t.integer "requested_by_id"
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_belnet_validations_on_plan_id"
    t.index ["requested_by_id"], name: "index_belnet_validations_on_requested_by_id"
    t.index ["reviewed_by_id"], name: "index_belnet_validations_on_reviewed_by_id"
    t.index ["validated_plan_id"], name: "index_belnet_validations_on_validated_plan_id"
  end

  create_table "conditions", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.text "option_list"
    t.integer "action_type"
    t.integer "number"
    t.text "remove_data"
    t.text "webhook_data"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["question_id"], name: "idx_132088877_index_conditions_on_question_id"
  end

  create_table "contributors", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "email", limit: 255
    t.string "phone", limit: 255
    t.integer "roles", null: false
    t.integer "org_id"
    t.integer "plan_id", null: false
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["email"], name: "idx_132088884_index_contributors_on_email"
    t.index ["org_id"], name: "idx_132088884_index_contributors_on_org_id"
    t.index ["plan_id"], name: "idx_132088884_index_contributors_on_plan_id"
    t.index ["roles"], name: "idx_132088884_index_contributors_on_roles"
  end

  create_table "departments", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.integer "org_id"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["org_id"], name: "idx_132088891_index_departments_on_org_id"
  end

  create_table "exported_plans", id: :serial, force: :cascade do |t|
    t.integer "plan_id"
    t.integer "user_id"
    t.string "format", limit: 255
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.integer "phase_id"
  end

  create_table "guidance_groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "org_id"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.boolean "optional_subset", default: false, null: false
    t.boolean "published", default: false, null: false
    t.index ["org_id"], name: "idx_132088903_index_guidance_groups_on_org_id"
  end

  create_table "guidances", id: :serial, force: :cascade do |t|
    t.text "text"
    t.integer "guidance_group_id"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.boolean "published"
    t.index ["guidance_group_id"], name: "idx_132088910_index_guidances_on_guidance_group_id"
  end

  create_table "identifier_schemes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.boolean "active"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.text "logo_url"
    t.text "identifier_prefix"
    t.integer "context"
  end

  create_table "identifiers", id: :serial, force: :cascade do |t|
    t.string "value", limit: 255, null: false
    t.text "attrs"
    t.integer "identifier_scheme_id"
    t.integer "identifiable_id"
    t.string "identifiable_type", limit: 255
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.string "label", limit: 255
    t.index ["identifiable_type", "identifiable_id"], name: "idx_132088924_index_identifiers_on_identifiable_type_and_identi"
    t.index ["identifier_scheme_id", "identifiable_id", "identifiable_type"], name: "idx_132088924_index_identifiers_on_scheme_and_type_and_id"
    t.index ["identifier_scheme_id", "value"], name: "idx_132088924_index_identifiers_on_identifier_scheme_id_and_val"
  end

  create_table "languages", id: :serial, force: :cascade do |t|
    t.string "abbreviation", limit: 255
    t.string "description", limit: 255
    t.string "name", limit: 255
    t.boolean "default_language"
  end

  create_table "licenses", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "identifier", limit: 255, null: false
    t.string "uri", limit: 255, null: false
    t.boolean "osi_approved", default: false
    t.boolean "deprecated", default: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["identifier", "osi_approved", "deprecated"], name: "idx_132088938_index_license_on_identifier_and_criteria"
    t.index ["identifier"], name: "idx_132088938_index_licenses_on_identifier"
    t.index ["uri"], name: "idx_132088938_index_licenses_on_uri"
  end

  create_table "metadata_standards", force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.string "rdamsc_id", limit: 255
    t.string "uri", limit: 255
    t.json "locations"
    t.json "related_entities"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
  end

  create_table "metadata_standards_research_outputs", force: :cascade do |t|
    t.bigint "metadata_standard_id"
    t.bigint "research_output_id"
    t.index ["metadata_standard_id"], name: "idx_132088954_metadata_research_outputs_on_metadata"
    t.index ["research_output_id"], name: "idx_132088954_metadata_research_outputs_on_ro"
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "text"
    t.boolean "archived", default: false, null: false
    t.integer "answer_id"
    t.integer "archived_by"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["answer_id"], name: "idx_132088959_index_notes_on_answer_id"
    t.index ["user_id"], name: "idx_132088959_fk_rails_7f2323ad43"
  end

  create_table "notification_acknowledgements", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "notification_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["notification_id"], name: "idx_132088967_index_notification_acknowledgements_on_notificati"
    t.index ["user_id"], name: "idx_132088967_index_notification_acknowledgements_on_user_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "notification_type"
    t.string "title", limit: 255
    t.integer "level"
    t.text "body"
    t.boolean "dismissable"
    t.date "starts_at"
    t.date "expires_at"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.boolean "enabled", default: true
  end

  create_table "options_themes", id: false, force: :cascade do |t|
    t.integer "option_id", null: false
    t.integer "theme_id", null: false
    t.index ["option_id", "theme_id"], name: "idx_132088979_index_options_themes_on_option_id_and_theme_id"
  end

  create_table "org_token_permissions", id: :serial, force: :cascade do |t|
    t.integer "org_id"
    t.integer "token_permission_type_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["org_id"], name: "idx_132088983_index_org_token_permissions_on_org_id"
    t.index ["token_permission_type_id"], name: "idx_132088983_fk_rails_2aa265f538"
  end

  create_table "orgs", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "abbreviation", limit: 255
    t.string "target_url", limit: 255
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.boolean "is_other", default: false, null: false
    t.integer "region_id"
    t.integer "language_id"
    t.string "logo_uid", limit: 255
    t.string "logo_name", limit: 255
    t.string "contact_email", limit: 255
    t.integer "org_type", default: 0, null: false
    t.text "links"
    t.string "contact_name", limit: 255
    t.boolean "feedback_enabled", default: false
    t.text "feedback_msg"
    t.boolean "managed", default: false, null: false
    t.string "helpdesk_email", limit: 255
    t.index ["language_id"], name: "idx_132088988_fk_rails_5640112cab"
    t.index ["region_id"], name: "idx_132088988_fk_rails_5a6adf6bab"
  end

  create_table "perms", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
  end

  create_table "phases", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.integer "number"
    t.integer "template_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.boolean "modifiable"
    t.string "versionable_id", limit: 36
    t.index ["template_id"], name: "idx_132089004_index_phases_on_template_id"
    t.index ["versionable_id"], name: "idx_132089004_index_phases_on_versionable_id"
  end

  create_table "plans", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.integer "template_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.string "identifier", limit: 255
    t.text "description"
    t.integer "visibility", default: 3, null: false
    t.boolean "feedback_requested", default: false
    t.boolean "complete", default: false
    t.integer "org_id"
    t.integer "funder_id"
    t.integer "grant_id"
    t.timestamptz "start_date"
    t.timestamptz "end_date"
    t.bigint "research_domain_id"
    t.boolean "ethical_issues"
    t.text "ethical_issues_description"
    t.string "ethical_issues_report", limit: 255
    t.integer "funding_status"
    t.integer "api_client_id"
    t.integer "belnet_version", default: 0, null: false
    t.integer "belnet_family_id"
    t.index ["funder_id"], name: "idx_132089011_index_plans_on_funder_id"
    t.index ["grant_id"], name: "idx_132089011_index_plans_on_grant_id"
    t.index ["org_id"], name: "idx_132089011_index_plans_on_org_id"
    t.index ["research_domain_id"], name: "idx_132089011_index_plans_on_research_domain_id"
    t.index ["template_id"], name: "idx_132089011_index_plans_on_template_id"
  end

  create_table "plans_guidance_groups", id: :serial, force: :cascade do |t|
    t.integer "guidance_group_id"
    t.integer "plan_id"
    t.index ["guidance_group_id", "plan_id"], name: "idx_132089021_index_plans_guidance_groups_on_guidance_group_id_"
    t.index ["plan_id"], name: "idx_132089021_fk_rails_13d0671430"
  end

  create_table "prefs", id: :serial, force: :cascade do |t|
    t.text "settings"
    t.integer "user_id"
  end

  create_table "project_partners", id: :serial, force: :cascade do |t|
    t.integer "org_id"
    t.integer "project_id"
    t.boolean "leader_org"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
  end

  create_table "question_formats", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.boolean "option_based", default: false
    t.integer "formattype", default: 0
  end

  create_table "question_options", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.text "text"
    t.integer "number"
    t.boolean "is_default"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.string "versionable_id", limit: 36
    t.index ["question_id"], name: "idx_132089047_index_question_options_on_question_id"
    t.index ["versionable_id"], name: "idx_132089047_index_question_options_on_versionable_id"
  end

  create_table "question_options_themes", id: :serial, force: :cascade do |t|
    t.integer "question_option_id", null: false
    t.integer "theme_id", null: false
  end

  create_table "questions", id: :serial, force: :cascade do |t|
    t.text "text"
    t.text "default_value"
    t.integer "number"
    t.integer "section_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "question_format_id"
    t.boolean "option_comment_display", default: true
    t.boolean "modifiable"
    t.string "versionable_id", limit: 36
    t.index ["question_format_id"], name: "idx_132089059_fk_rails_4fbc38c8c7"
    t.index ["section_id"], name: "idx_132089059_index_questions_on_section_id"
    t.index ["versionable_id"], name: "idx_132089059_index_questions_on_versionable_id"
  end

  create_table "questions_themes", id: false, force: :cascade do |t|
    t.integer "question_id", null: false
    t.integer "theme_id", null: false
    t.index ["question_id"], name: "idx_132089066_index_questions_themes_on_question_id"
    t.index ["theme_id"], name: "idx_132089066_fk_rails_0489d5eeba"
  end

  create_table "regions", id: :serial, force: :cascade do |t|
    t.string "abbreviation", limit: 255
    t.string "description", limit: 255
    t.string "name", limit: 255
    t.integer "super_region_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.text "description", null: false
    t.string "homepage", limit: 255
    t.string "contact", limit: 255
    t.string "uri", limit: 255, null: false
    t.json "info"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["homepage"], name: "idx_132089077_index_repositories_on_homepage"
    t.index ["name"], name: "idx_132089077_index_repositories_on_name"
    t.index ["uri"], name: "idx_132089077_index_repositories_on_uri"
  end

  create_table "repositories_research_outputs", force: :cascade do |t|
    t.bigint "research_output_id"
    t.bigint "repository_id"
    t.index ["repository_id"], name: "idx_132089084_index_repositories_research_outputs_on_repository"
    t.index ["research_output_id"], name: "idx_132089084_index_repositories_research_outputs_on_research_o"
  end

  create_table "research_domains", force: :cascade do |t|
    t.string "identifier", limit: 255, null: false
    t.string "label", limit: 255, null: false
    t.bigint "parent_id"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["parent_id"], name: "idx_132089089_index_research_domains_on_parent_id"
  end

  create_table "research_outputs", force: :cascade do |t|
    t.integer "plan_id"
    t.integer "output_type", default: 3, null: false
    t.string "output_type_description", limit: 255
    t.string "title", limit: 255, null: false
    t.string "abbreviation", limit: 255
    t.integer "display_order"
    t.boolean "is_default"
    t.text "description"
    t.integer "access", default: 0, null: false
    t.timestamptz "release_date"
    t.boolean "personal_data"
    t.boolean "sensitive_data"
    t.bigint "byte_size"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.bigint "license_id"
    t.index ["license_id"], name: "idx_132089096_index_research_outputs_on_license_id"
    t.index ["output_type"], name: "idx_132089096_index_research_outputs_on_output_type"
    t.index ["plan_id"], name: "idx_132089096_index_research_outputs_on_plan_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "plan_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "access", default: 0, null: false
    t.boolean "active", default: true
    t.index ["plan_id"], name: "idx_132089105_index_roles_on_plan_id"
    t.index ["user_id"], name: "idx_132089105_index_roles_on_user_id"
  end

  create_table "sections", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.integer "number"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "phase_id"
    t.boolean "modifiable"
    t.string "versionable_id", limit: 36
    t.index ["phase_id"], name: "idx_132089115_index_sections_on_phase_id"
    t.index ["versionable_id"], name: "idx_132089115_index_sections_on_versionable_id"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 64, null: false
    t.text "data"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["session_id"], name: "idx_132089122_index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "idx_132089122_index_sessions_on_updated_at"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "var", limit: 255, null: false
    t.text "value"
    t.integer "target_id", null: false
    t.string "target_type", limit: 255, null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
  end

  create_table "stats", id: :serial, force: :cascade do |t|
    t.bigint "count", default: 0
    t.date "date", null: false
    t.string "type", limit: 255, null: false
    t.integer "org_id"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.text "details"
    t.boolean "filtered", default: false
  end

  create_table "templates", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.boolean "published"
    t.integer "org_id"
    t.string "locale", limit: 255
    t.boolean "is_default"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "version"
    t.integer "visibility"
    t.integer "customization_of"
    t.integer "family_id"
    t.boolean "archived"
    t.text "links"
    t.index ["family_id", "version"], name: "idx_132089145_index_templates_on_family_id_and_version", unique: true
    t.index ["family_id"], name: "idx_132089145_index_templates_on_family_id"
    t.index ["org_id", "family_id"], name: "idx_132089145_template_organisation_dmptemplate_index"
    t.index ["org_id"], name: "idx_132089145_index_templates_on_org_id"
  end

  create_table "themes", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.string "locale", limit: 255
  end

  create_table "themes_in_guidance", id: false, force: :cascade do |t|
    t.integer "theme_id"
    t.integer "guidance_id"
    t.index ["guidance_id"], name: "idx_132089160_index_themes_in_guidance_on_guidance_id"
    t.index ["theme_id"], name: "idx_132089160_index_themes_in_guidance_on_theme_id"
  end

  create_table "token_permission_types", id: :serial, force: :cascade do |t|
    t.string "token_type", limit: 255
    t.text "text_description"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
  end

  create_table "trackers", id: :serial, force: :cascade do |t|
    t.integer "org_id"
    t.string "code", limit: 255
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["org_id"], name: "idx_132089171_index_trackers_on_org_id"
  end

  create_table "ugent_logs", id: :serial, force: :cascade do |t|
    t.integer "item_id"
    t.string "item_type", limit: 255
    t.string "event", limit: 255
    t.text "whodunnit"
    t.integer "whodunnit_id"
    t.text "object"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["event"], name: "idx_132089176_index_ugent_logs_on_event"
    t.index ["item_type"], name: "idx_132089176_index_ugent_logs_on_item_type"
    t.index ["whodunnit_id"], name: "idx_132089176_index_ugent_logs_on_whodunnit_id"
  end

  create_table "ugent_org_domains", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.integer "org_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["name"], name: "idx_132089183_index_organisation_domains_on_name", unique: true
  end

  create_table "ugent_rest_users", id: :serial, force: :cascade do |t|
    t.string "code", limit: 255
    t.string "token", limit: 255
    t.integer "org_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
  end

  create_table "ugent_wayfless_entities", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.text "url", null: false
    t.integer "org_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["name"], name: "idx_132089195_index_wayfless_entities_on_name", unique: true
    t.index ["url"], name: "idx_132089195_index_wayfless_entities_on_url", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "firstname", limit: 255
    t.string "surname", limit: 255
    t.string "email", limit: 80, default: "", null: false
    t.integer "user_type_id"
    t.integer "user_status_id"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.string "encrypted_password", limit: 255, default: ""
    t.string "reset_password_token", limit: 255
    t.timestamptz "reset_password_sent_at"
    t.timestamptz "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.timestamptz "current_sign_in_at"
    t.timestamptz "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "confirmation_token", limit: 255
    t.timestamptz "confirmed_at"
    t.timestamptz "confirmation_sent_at"
    t.string "invitation_token", limit: 255
    t.timestamptz "invitation_created_at"
    t.timestamptz "invitation_sent_at"
    t.timestamptz "invitation_accepted_at"
    t.boolean "dmponline3"
    t.boolean "accept_terms"
    t.integer "org_id"
    t.string "other_organisation", limit: 255
    t.string "api_token", limit: 255
    t.integer "invited_by_id"
    t.string "invited_by_type", limit: 255
    t.integer "language_id"
    t.string "recovery_email", limit: 255
    t.boolean "active", default: true
    t.integer "department_id"
    t.timestamptz "last_api_access"
    t.index ["department_id"], name: "idx_132089202_fk_rails_f29bf9cdf2"
    t.index ["email"], name: "idx_132089202_index_users_on_email", unique: true
    t.index ["language_id"], name: "idx_132089202_fk_rails_45f4f12508"
    t.index ["org_id"], name: "idx_132089202_index_users_on_org_id"
  end

  create_table "users_perms", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "perm_id"
    t.index ["perm_id"], name: "idx_132089212_fk_rails_457217c31c"
    t.index ["user_id"], name: "idx_132089212_index_users_perms_on_user_id"
  end

  add_foreign_key "annotations", "orgs", on_update: :restrict, on_delete: :restrict
  add_foreign_key "annotations", "questions", on_update: :restrict, on_delete: :restrict
  add_foreign_key "answers", "plans", on_update: :restrict, on_delete: :restrict
  add_foreign_key "answers", "questions", on_update: :restrict, on_delete: :restrict
  add_foreign_key "answers", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "answers_question_options", "answers", on_update: :restrict, on_delete: :restrict
  add_foreign_key "answers_question_options", "question_options", on_update: :restrict, on_delete: :restrict
  add_foreign_key "belnet_config_lifecycle_stages", "orgs"
  add_foreign_key "belnet_config_validation_statuses", "orgs"
  add_foreign_key "belnet_config_validation_topics", "orgs"
  add_foreign_key "belnet_editable_plan_metadata", "plans"
  add_foreign_key "belnet_editable_plan_metadata", "users", column: "created_by_id"
  add_foreign_key "belnet_editable_plan_metadata", "users", column: "updated_by_id"
  add_foreign_key "belnet_plan_version_metadata", "plans"
  add_foreign_key "belnet_plan_version_metadata", "plans", column: "editable_plan_id"
  add_foreign_key "belnet_plan_version_metadata", "plans", column: "versioned_plan_id"
  add_foreign_key "belnet_plan_version_metadata", "users", column: "created_by_id"
  add_foreign_key "belnet_plan_version_metadata", "users", column: "updated_by_id"
  add_foreign_key "belnet_stage_histories", "plans"
  add_foreign_key "belnet_stage_histories", "users"
  add_foreign_key "belnet_validations", "plans"
  add_foreign_key "belnet_validations", "plans", column: "validated_plan_id"
  add_foreign_key "belnet_validations", "users", column: "requested_by_id"
  add_foreign_key "belnet_validations", "users", column: "reviewed_by_id"
  add_foreign_key "conditions", "questions", on_update: :restrict, on_delete: :restrict
  add_foreign_key "guidance_groups", "orgs", on_update: :restrict, on_delete: :restrict
  add_foreign_key "guidances", "guidance_groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "notes", "answers", on_update: :restrict, on_delete: :restrict
  add_foreign_key "notes", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "notification_acknowledgements", "notifications", on_update: :restrict, on_delete: :restrict
  add_foreign_key "notification_acknowledgements", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "org_token_permissions", "orgs", on_update: :restrict, on_delete: :restrict
  add_foreign_key "org_token_permissions", "token_permission_types", on_update: :restrict, on_delete: :restrict
  add_foreign_key "orgs", "languages", on_update: :restrict, on_delete: :restrict
  add_foreign_key "orgs", "regions", on_update: :restrict, on_delete: :restrict
  add_foreign_key "phases", "templates", on_update: :restrict, on_delete: :restrict
  add_foreign_key "plans", "orgs", on_update: :restrict, on_delete: :restrict
  add_foreign_key "plans", "templates", on_update: :restrict, on_delete: :restrict
  add_foreign_key "plans_guidance_groups", "guidance_groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "plans_guidance_groups", "plans", on_update: :restrict, on_delete: :restrict
  add_foreign_key "question_options", "questions", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions", "question_formats", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions", "sections", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions_themes", "questions", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions_themes", "themes", on_update: :restrict, on_delete: :restrict
  add_foreign_key "research_domains", "research_domains", column: "parent_id", on_update: :restrict, on_delete: :restrict
  add_foreign_key "research_outputs", "licenses", on_update: :restrict, on_delete: :restrict
  add_foreign_key "roles", "plans", on_update: :restrict, on_delete: :restrict
  add_foreign_key "roles", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "sections", "phases", on_update: :restrict, on_delete: :restrict
  add_foreign_key "templates", "orgs", on_update: :restrict, on_delete: :restrict
  add_foreign_key "themes_in_guidance", "guidances", on_update: :restrict, on_delete: :restrict
  add_foreign_key "themes_in_guidance", "themes", on_update: :restrict, on_delete: :restrict
  add_foreign_key "trackers", "orgs", on_update: :restrict, on_delete: :restrict
  add_foreign_key "users", "departments", on_update: :restrict, on_delete: :restrict
  add_foreign_key "users", "languages", on_update: :restrict, on_delete: :restrict
  add_foreign_key "users", "orgs", on_update: :restrict, on_delete: :restrict
  add_foreign_key "users_perms", "perms", on_update: :restrict, on_delete: :restrict
  add_foreign_key "users_perms", "users", on_update: :restrict, on_delete: :restrict
end
