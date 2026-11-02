# frozen_string_literal: true

# Attributes an order to the employee credited with the sale. One order has at
# most one employee (product decision: no split credit). Historical orders stay
# NULL and surface as "unattributed" in the KPI UI.
class AddEmployeeToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :employee, type: :uuid, null: true,
      foreign_key: { to_table: :employees, on_delete: :nullify }
    add_index :orders, [ :company_id, :employee_id, :created_at ],
      name: "index_orders_on_company_employee_created_at"
  end
end
