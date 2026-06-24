class CreateContractMetrics < ActiveRecord::Migration[8.0]
  def change
    create_table :contract_metrics, id: :uuid do |t|
      t.references :billing_resource, null: false, foreign_key: true, type: :uuid
      t.references :billing_contract, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.integer :free_allowance, default: 0, null: false

      # money-rails metrics formatting
      t.integer :unit_price_cents, default: 0, null: false
      t.string :unit_price_currency, default: "USD", null: false

      t.integer  :lifecycle_status, default: 0, index: true
      t.integer  :workflow_status, default: 0, index: true
      t.timestamps
    end

    # Critical index to prevent attaching duplicate metrics to the same contract
    add_index :contract_metrics, [ :billing_contract_id, :billing_resource_id ], unique: true, name: "index_contract_metrics_on_contract_and_resource"
  end
end
