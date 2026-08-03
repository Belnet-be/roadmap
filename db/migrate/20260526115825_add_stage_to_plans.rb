# frozen_string_literal: true

class AddStageToPlans < ActiveRecord::Migration[7.1]
  def change
    # We need 2 tables, one for the stages themselves, and one for the history of stage changes (with motivation and user)
    create_table :belnet_stages do |t|
      t.string :name_id, null: false
      t.string :description
      t.boolean :deprecated, null: false, default: false
      # t.boolean :is_active, null: false, default: true
      # null true means that if org is nil, stage is global
      t.references :org, type: :integer, foreign_key: true, null: true
      # t.boolean :is_global, default: true, null: false
      t.timestamps
    end

    create_table :belnet_editable_plan_metadata do |t|
      t.references :plan, type: :integer, foreign_key: true, null: false
      t.references :created_by, type: :integer, foreign_key: { to_table: :users }
      t.references :updated_by, type: :integer, foreign_key: { to_table: :users }
      t.references :belnet_stage, foreign_key: true
      t.string :lifecycle_stage, null: true
      t.timestamps
    end

    create_table :belnet_plan_version_metadata do |t|
      t.references :plan, type: :integer, foreign_key: true, null: false
      t.references :created_by, type: :integer, foreign_key: { to_table: :users }
      t.references :updated_by, type: :integer, foreign_key: { to_table: :users }
      t.references :editable_plan, type: :integer, foreign_key: { to_table: :plans }
      t.references :versioned_plan, type: :integer, foreign_key: { to_table: :plans }
      t.string :lifecycle_stage, null: true
      t.timestamps
    end
    
    add_column :orgs, :belnet_stages_order, :json
    add_index :belnet_stages, %i[org_id name_id], unique: true

    create_table :belnet_stage_histories do |t|
      t.string :motivation
      t.references :plan, type: :integer, foreign_key: true, null: false
      t.references :belnet_stage, foreign_key: true
      t.references :user, type: :integer, foreign_key: true
      t.timestamps
    end
  end
end