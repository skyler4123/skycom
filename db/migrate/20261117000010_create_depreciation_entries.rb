class CreateDepreciationEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :depreciation_entries, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :fixed_asset, null: false, foreign_key: true, type: :uuid
      t.references :fiscal_period, null: false, foreign_key: true, type: :uuid
      t.references :journal_entry, foreign_key: true, type: :uuid

      # --- Charge ---
      t.bigint  :amount_cents, null: false, default: 0
      t.bigint  :accumulated_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.datetime :posted_at

      t.timestamps
    end

    add_index :depreciation_entries, [ :fixed_asset_id, :fiscal_period_id ], unique: true
  end
end
