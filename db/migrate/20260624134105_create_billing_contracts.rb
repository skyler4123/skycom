class CreateBillingContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_contracts, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.string :description
      t.integer :contract_type, null: false # enum: basic, pay_as_you_go, enterprise

      # money-rails flat column format
      t.integer :fixed_monthly_price_cents, null: false
      t.integer :currency, null: false

      t.datetime :start_date, null: false
      t.datetime :end_time

      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.timestamps
    end
  end
end
