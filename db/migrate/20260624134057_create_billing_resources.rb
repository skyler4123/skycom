class CreateBillingResources < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_resources, id: :uuid do |t|
      t.string :name, null: false, index: { unique: true }
      t.text   :description
      t.integer :resource_type, default: 0, null: false # enum: volumetric, addon_feature

      t.integer  :lifecycle_status, default: 0, index: true
      t.integer  :workflow_status, default: 0, index: true
      t.timestamps
    end
  end
end