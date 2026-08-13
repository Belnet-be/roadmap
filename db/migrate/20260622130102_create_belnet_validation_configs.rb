# frozen_string_literal: true

class CreateBelnetValidationConfigs < ActiveRecord::Migration[7.1]
  def change
    # Config table for validation topics. One row per org (or global)
    create_table :belnet_config_validation_topics do |t|
      t.references :org, type: :integer, foreign_key: true, null: true
      t.json :current_list_order
      t.json :full_list_order
      t.timestamps
    end

    create_table :belnet_config_validation_statuses do |t|
      t.references :org, type: :integer, foreign_key: true, null: true
      t.json :current_list_order
      t.json :full_list_order
      t.timestamps
    end

    create_table :belnet_validations do |t|
      t.references :plan, type: :integer, foreign_key: true, null: false
      t.references :validated_plan, type: :integer, foreign_key: { to_table: :plans }, null: false
      t.string :validation_topic, null: false
      t.string :validation_status
      t.text :rationale
      t.text :conditions
      t.references :requested_by, type: :integer, foreign_key: { to_table: :users }
      # requested_at lifts on created_at; reviewed_at is separate because a
      # review can happen well after the request was recorded.
      t.references :reviewed_by, type: :integer, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.timestamps
    end
  end
end