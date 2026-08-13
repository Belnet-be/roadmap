# frozen_string_literal: true

class AddStageToPlans < ActiveRecord::Migration[7.1]
  def change
    # Config table for lifecycle stages. One row per org (or global when
    # org_id is nil). Stage names are stored as strings in the JSON arrays:
    # - current_list_order: the active, user-facing ordered list
    # - full_list_order: superset that also carries deprecated names,
    # so history/audit lookups still resolve.
    create_table :belnet_config_lifecycle_stages do |t|
      t.references :org, type: :integer, foreign_key: true, null: true
      t.json :current_list_order
      t.json :full_list_order
      t.timestamps
    end

    # Editable  plan metadata (one row per LIVE plan).
    create_table :belnet_editable_plan_metadata do |t|
      t.references :plan, type: :integer, foreign_key: true, null: false
      t.references :created_by, type: :integer, foreign_key: { to_table: :users }
      t.references :updated_by, type: :integer, foreign_key: { to_table: :users }
      t.string :lifecycle_stage
      t.timestamps
    end

    # version metadata (one row per version)
    create_table :belnet_plan_version_metadata do |t|
      # perhaps rename to :validated_plan
      t.references :plan, type: :integer, foreign_key: true, null: false
      t.references :created_by, type: :integer, foreign_key: { to_table: :users }
      t.references :updated_by, type: :integer, foreign_key: { to_table: :users }
      t.references :editable_plan, type: :integer, foreign_key: { to_table: :plans }
      t.references :versioned_plan, type: :integer, foreign_key: { to_table: :plans }
      t.text :reason
      t.string :lifecycle_stage
      t.timestamps
    end


    create_table :belnet_stage_histories do |t|
      t.string :motivation
      t.string :lifecycle_stage
      t.references :plan, type: :integer, foreign_key: true, null: false
      t.references :user, type: :integer, foreign_key: true
      t.timestamps
    end
  end
end