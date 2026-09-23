class AddWarehouseToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_reference :purchases, :warehouse, foreign_key: true, type: :uuid

    # Backfill: purchases land in the company's first warehouse (dev seed rows
    # predate the destination-warehouse concept).
    execute <<~SQL
      UPDATE purchases
      SET warehouse_id = sub.warehouse_id
      FROM (
        SELECT company_id, MIN(id::text)::uuid AS warehouse_id
        FROM warehouses
        GROUP BY company_id
      ) sub
      WHERE purchases.company_id = sub.company_id
        AND purchases.warehouse_id IS NULL
    SQL

    change_column_null :purchases, :warehouse_id, false
  end
end
