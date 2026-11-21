# frozen_string_literal: true

class AddRecipientEmployeeToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_reference :notifications, :recipient_employee, type: :uuid, foreign_key: { to_table: :employees }
    add_index :notifications, [ :company_id, :recipient_employee_id ]
  end
end
