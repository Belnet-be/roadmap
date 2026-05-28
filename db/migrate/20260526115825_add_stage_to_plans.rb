class AddStageToPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :plans, :belnet_stage, :string

    # Type integer needed because of the foreign key reference to users table
    add_reference :plans, :belnet_stage_updated_by, type: :integer, foreign_key: { to_table: :users }, index: true

    add_index :plans, :belnet_stage
  end
end