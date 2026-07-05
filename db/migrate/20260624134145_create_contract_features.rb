class CreateContractFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :contract_features, id: :uuid do |t|
      t.references :billing_resource, null: false, foreign_key: true, type: :uuid
      t.references :billing_contract, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.string :description

      # money-rails formatting for flat monthly add-on pricing
      t.integer :monthly_flat_price_cents, default: 0, null: false
      t.string :monthly_flat_price_currency, default: "USD", null: false

      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, default: 0, index: true
      t.timestamps
    end

    # Critical index to prevent attaching the same add-on twice to the same contract
    add_index :contract_features, [ :billing_contract_id, :billing_resource_id ], unique: true, name: "index_contract_features_on_contract_and_resource"
  end
end
