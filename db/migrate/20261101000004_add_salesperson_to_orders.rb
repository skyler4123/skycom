# frozen_string_literal: true

# Attributes an order to the employee who sold it. One order has at most one
# salesperson (product decision: no split credit). Historical orders stay NULL
# and surface as "unattributed" in the KPI UI.
class AddSalespersonToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :salesperson, type: :uuid, null: true,
      foreign_key: { to_table: :employees, on_delete: :nullify }
    add_index :orders, [ :company_id, :salesperson_id, :created_at ],
      name: "index_orders_on_company_salesperson_created_at"
  end
end
