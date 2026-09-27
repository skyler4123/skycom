class AddStockIdToOrderProductAppointments < ActiveRecord::Migration[8.0]
  def change
    add_reference :order_product_appointments, :stock, null: true, foreign_key: true, type: :uuid
  end
end
