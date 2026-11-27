# frozen_string_literal: true

class AddVisibilityToCompanyTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :company_tickets, :visibility, :integer, null: false, default: 1
    add_index :company_tickets, [ :company_id, :visibility ]
    add_index :company_tickets, [ :company_id, :employee_id ]
  end
end
