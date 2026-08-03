class CreateBelnetValidationConfigs < ActiveRecord::Migration[7.1]
  def change
    # name_id column acting as a code for API and viewer facing labels
    # description is a human readable text about the topic/status
    
    create_table :belnet_validation_topics do |t|
      t.string :name_id, null: false
      t.string :description
      t.boolean :is_active, null: false, default: true
      # null false means that every topic must belong to a specific org.
      t.references :org, type: :integer, foreign_key: true, null: false 
      t.timestamps
    end
    add_index :belnet_validation_topics, %i[org_id name_id], unique: true

    create_table :belnet_validation_statuses do |t|
      t.string :name_id, null: false
      t.string :description
      t.boolean :is_active, null: false, default: true
      # null false means that every status must belong to a specific org, the same way for stages
      t.references :org, type: :integer, foreign_key: true, null: false
      t.timestamps
    end
    add_index :belnet_validation_statuses, %i[org_id name_id], unique: true

    create_table :belnet_validations do |t|
      t.references :plan, type: :integer, foreign_key: true, null: false 
      t.references :validated_plan, type: :integer, foreign_key: { to_table: :plans }, null: false 
      t.references :belnet_validation_topic, foreign_key: true, null: false
      t.references :belnet_validation_status, foreign_key: true
      t.text :rationale
      t.text :conditions
      t.references :requested_by, type: :integer, foreign_key: { to_table: :users }
      # for requested_at we can lift on created_at, but for decided_at we need a separate column, because the decision can be made later than the creation of the record.
      t.references :decided_by, type: :integer, foreign_key: { to_table: :users }
      t.datetime :decided_at
      t.timestamps
    end
  end
end