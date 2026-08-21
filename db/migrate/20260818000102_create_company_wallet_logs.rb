# frozen_string_literal: true

class CreateCompanyWalletLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :company_wallet_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :company_wallet, null: false, foreign_key: true, type: :uuid
      t.string :source_type
      t.uuid :source_id
      t.integer :change_type, null: false
      t.bigint :change_amount, null: false
      t.bigint :balance_before, null: false
      t.bigint :balance_after, null: false
      t.text :description
      t.integer :balance_type

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :company_wallet_logs, [ :company_wallet_id, :created_at ]
    add_index :company_wallet_logs, [ :source_type, :source_id ]
  end
end
