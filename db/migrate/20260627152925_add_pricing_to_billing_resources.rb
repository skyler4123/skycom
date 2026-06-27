class AddPricingToBillingResources < ActiveRecord::Migration[8.0]
  def change
    add_column :billing_resources, :country_code, :integer
    add_column :billing_resources, :price_cents, :integer, default: 0, null: false
    add_column :billing_resources, :currency, :string, default: "USD", null: false

    remove_index :billing_resources, :name
    add_index :billing_resources, [ :name, :country_code ], unique: true
  end
end
