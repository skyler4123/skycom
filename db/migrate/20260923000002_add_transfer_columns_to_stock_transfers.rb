class AddTransferColumnsToStockTransfers < ActiveRecord::Migration[8.0]
  def change
    add_reference :stock_transfers, :destination_warehouse, foreign_key: { to_table: :warehouses }, type: :uuid
    add_column :stock_transfers, :initiated_at, :datetime
    add_column :stock_transfers, :received_at, :datetime

    # Backfill: existing seeded transfers had no destination — default to the
    # source warehouse (self-transfer) so the NOT NULL constraint can apply.
    execute <<~SQL
      UPDATE stock_transfers
      SET destination_warehouse_id = warehouse_id
      WHERE destination_warehouse_id IS NULL
    SQL

    change_column_null :stock_transfers, :destination_warehouse_id, false
  end
end
