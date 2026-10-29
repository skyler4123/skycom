# frozen_string_literal: true

class AddCompensationToEmployees < ActiveRecord::Migration[8.1]
  def change
    add_column :employees, :monthly_salary_cents, :integer, null: false, default: 0
    add_column :employees, :monthly_allowance_cents, :integer, null: false, default: 0
  end
end
