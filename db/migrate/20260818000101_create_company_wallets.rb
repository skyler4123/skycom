# frozen_string_literal: true

class CreateCompanyWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :company_wallets, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string :walletable_type, null: false
      t.uuid :walletable_id, null: false
      t.bigint :credit_balance, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.datetime :usage_logging_until

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :company_wallets, :company_id, unique: true
    add_index :company_wallets, [ :walletable_type, :walletable_id ]
  end
end
