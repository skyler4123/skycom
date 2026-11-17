class CreateDisbursementBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :disbursement_batches, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, foreign_key: true, type: :uuid
      t.references :stored_file, foreign_key: true, type: :uuid

      # --- Batch ---
      t.string  :name, null: false
      t.date    :payment_on, null: false
      t.string  :bank_account
      t.bigint  :total_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.integer :status, null: false, default: 0
      t.text    :notes

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :disbursement_batches, [ :company_id, :payment_on ]
  end
end
