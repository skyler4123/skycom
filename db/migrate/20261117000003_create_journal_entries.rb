class CreateJournalEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_entries, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, foreign_key: true, type: :uuid
      t.references :fiscal_period, foreign_key: true, type: :uuid

      # --- Entry ---
      t.date    :entry_date, null: false
      t.string  :code
      t.text    :memo
      t.string  :source_type
      t.uuid    :source_id
      t.string  :event_key, null: false
      t.integer :status, null: false, default: 0

      # --- Posting ---
      t.datetime :posted_at
      t.references :posted_by_employee, foreign_key: { to_table: :employees }, type: :uuid
      t.references :reversal_of, foreign_key: { to_table: :journal_entries }, type: :uuid

      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :journal_entries, [ :company_id, :source_type, :source_id, :event_key ], unique: true, name: "idx_journal_entries_idempotency"
    add_index :journal_entries, [ :company_id, :entry_date ]
  end
end
