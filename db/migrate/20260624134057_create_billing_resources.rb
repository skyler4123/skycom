class CreateBillingResources < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_resources, id: :uuid do |t|
      t.string :name, null: false
      t.text   :description
      t.integer :resource_type, null: false # enum: volumetric, addon_feature
      t.integer :country_code
      t.integer :price_cents, null: false
      t.string  :currency, null: false

      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.index [ :name, :country_code ], unique: true
      t.timestamps
    end
  end
end
