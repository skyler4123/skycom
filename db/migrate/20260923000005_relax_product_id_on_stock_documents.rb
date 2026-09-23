class RelaxProductIdOnStockDocuments < ActiveRecord::Migration[8.0]
  def change
    # Movement documents are now multi-line (StockItemAppointment lines point at
    # specific Stock rows) — the document-level product_id becomes optional
    # metadata (kept as the first line's product for display compat).
    change_column_null :stock_imports, :product_id, true
    change_column_null :stock_exports, :product_id, true
    change_column_null :stock_transfers, :product_id, true
  end
end
