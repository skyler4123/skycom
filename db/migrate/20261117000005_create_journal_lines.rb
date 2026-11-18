class CreateJournalLines < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_lines, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :journal_entry, null: false, foreign_key: true, type: :uuid
      t.references :ledger_account, null: false, foreign_key: true, type: :uuid

      # --- Dimensions ---
      t.references :branch, foreign_key: true, type: :uuid
      t.references :department, foreign_key: true, type: :uuid
      t.references :cost_center, foreign_key: true, type: :uuid
      t.references :employee, foreign_key: true, type: :uuid
      t.references :customer, foreign_key: true, type: :uuid
      t.references :supplier, foreign_key: true, type: :uuid
      t.references :product, foreign_key: true, type: :uuid
      t.references :project, foreign_key: true, type: :uuid

      # --- Amount ---
      t.bigint  :debit_cents,  null: false, default: 0
      t.bigint  :credit_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.decimal :fx_rate,  precision: 18, scale: 10, default: "1.0"
      t.decimal :quantity, precision: 15, scale: 4
      t.string  :memo

      t.timestamps
    end

    add_index :journal_lines, [ :ledger_account_id, :cost_center_id ]
    add_index :journal_lines, [ :company_id, :branch_id ]
  end
end
