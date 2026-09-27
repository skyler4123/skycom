class AddStockIdToOrderServiceGroupAppointments < ActiveRecord::Migration[8.0]
  def change
    add_reference :order_service_group_appointments, :stock, null: true, foreign_key: true, type: :uuid
  end
end
