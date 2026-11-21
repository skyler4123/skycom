# frozen_string_literal: true

# One close-of-shift record per branch per business date. The row stores the
# figures printed on the report, not a recomputation: later sales must not
# rewrite a closed day.
class CreateShiftCloses < ActiveRecord::Migration[8.0]
  def change
    create_table :shift_closes, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.uuid :company_id, null: false
      t.uuid :branch_id, null: false
      t.uuid :closed_by_id
      t.date :business_date, null: false
      t.string :closed_by_name
      t.string :shift_name
      t.datetime :shift_started_at
      t.datetime :shift_ended_at
      t.bigint :gross_sales_cents, default: 0, null: false
      t.bigint :cash_sales_cents, default: 0, null: false
      t.bigint :qr_sales_cents, default: 0, null: false
      t.bigint :other_sales_cents, default: 0, null: false
      t.bigint :cash_received_cents, default: 0, null: false
      t.bigint :change_cents, default: 0, null: false
      t.bigint :orders_count, default: 0, null: false
      t.bigint :discounts_cents, default: 0, null: false
      t.bigint :tax_cents, default: 0, null: false
      t.bigint :opening_float_cents, default: 0, null: false
      t.bigint :expected_cash_cents, default: 0, null: false
      t.bigint :counted_cash_cents, default: 0, null: false
      t.bigint :variance_cents, default: 0, null: false
      t.integer :open_handovers_count, default: 0, null: false
      t.integer :shelf_short_count, default: 0, null: false
      t.jsonb :staff_names, default: [], null: false
      t.jsonb :shelf_snapshot, default: [], null: false
      t.jsonb :tender_lines, default: [], null: false
      t.text :note
      t.datetime :closed_at
      t.timestamps
    end

    add_index :shift_closes, [ :branch_id, :business_date ], unique: true
    add_index :shift_closes, [ :company_id, :business_date ]
    add_foreign_key :shift_closes, :companies
    add_foreign_key :shift_closes, :branches
    add_foreign_key :shift_closes, :employees, column: :closed_by_id
  end
end
