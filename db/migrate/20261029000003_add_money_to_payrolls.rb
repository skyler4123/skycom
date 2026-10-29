# frozen_string_literal: true

class AddMoneyToPayrolls < ActiveRecord::Migration[8.1]
  def change
    add_column :payrolls, :currency, :integer, null: false, default: 840
    add_column :payrolls, :base_amount_cents, :integer, null: false, default: 0
    add_column :payrolls, :allowance_amount_cents, :integer, null: false, default: 0
    add_column :payrolls, :overtime_amount_cents, :integer, null: false, default: 0
    add_column :payrolls, :gross_amount_cents, :integer, null: false, default: 0
    add_column :payrolls, :tax_amount_cents, :integer, null: false, default: 0
    add_column :payrolls, :deduction_amount_cents, :integer, null: false, default: 0
    add_column :payrolls, :net_amount_cents, :integer, null: false, default: 0
  end
end
