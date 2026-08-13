class AddVersionToPlans < ActiveRecord::Migration[7.1]
  def change
    # Family/family_id needed to group plans together, and version needed to track changes to plans over time.
    add_column :plans, :belnet_version, :integer, default: 0, null: false
    add_column :plans, :belnet_family_id, :integer, null: true
  end
end
