# frozen_string_literal: true

class ChangeMoneyColumnsToBigint < ActiveRecord::Migration[8.1]
  def change
    change_column :employees, :monthly_salary_cents, :bigint, null: false, default: 0
    change_column :employees, :monthly_allowance_cents, :bigint, null: false, default: 0

    change_column :payrolls, :base_amount_cents, :bigint, null: false, default: 0
    change_column :payrolls, :allowance_amount_cents, :bigint, null: false, default: 0
    change_column :payrolls, :overtime_amount_cents, :bigint, null: false, default: 0
    change_column :payrolls, :gross_amount_cents, :bigint, null: false, default: 0
    change_column :payrolls, :tax_amount_cents, :bigint, null: false, default: 0
    change_column :payrolls, :deduction_amount_cents, :bigint, null: false, default: 0
    change_column :payrolls, :net_amount_cents, :bigint, null: false, default: 0
  end
end
