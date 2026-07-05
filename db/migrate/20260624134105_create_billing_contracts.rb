class CreateBillingContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_contracts, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.string :description
      t.integer :contract_type, null: false # enum: basic, pay_as_you_go, enterprise

      # money-rails flat column format
      t.integer :fixed_monthly_price_cents, default: 0, null: false
      t.string :fixed_monthly_price_currency, default: "USD", null: false

      t.datetime :start_date, null: false
      t.datetime :end_time

      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, default: 0, index: true
      t.timestamps
    end
  end
end
