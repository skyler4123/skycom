# frozen_string_literal: true

class FixPayrollCurrencyDefault < ActiveRecord::Migration[8.1]
  def up
    change_column_default :payrolls, :currency, from: 0, to: 840
    execute "UPDATE payrolls SET currency = 840 WHERE currency = 0"
  end

  def down
    change_column_default :payrolls, :currency, from: 840, to: 0
  end
end
