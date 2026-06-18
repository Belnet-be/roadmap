# frozen_string_literal: true

class AddStageToPlans < ActiveRecord::Migration[7.1]
  def change
    # We need 2 tables, one for the stages themselves, and one for the history of stage changes (with motivation and user)
    create_table :belnet_stages do |t|
      t.string :code, null: false
      t.string :description
      t.boolean :is_active, null: false, default: true
      t.references :org, type: :integer, foreign_key: true
      t.timestamps
    end

    add_index :belnet_stages, %i[org_id code], unique: true

    create_table :belnet_stage_histories do |t|
      t.string :motivation
      t.references :plan, type: :integer, foreign_key: true, null: false
      t.references :belnet_stage, foreign_key: true
      t.references :user, type: :integer, foreign_key: true
      t.timestamps
    end

    add_reference :plans, :belnet_stage, foreign_key: true
  end
end
