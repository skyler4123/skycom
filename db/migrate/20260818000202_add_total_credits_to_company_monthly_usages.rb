# frozen_string_literal: true

class AddTotalCreditsToCompanyMonthlyUsages < ActiveRecord::Migration[8.0]
  def change
    add_column :company_monthly_usages, :total_credits, :bigint, null: false, default: 0
  end
end
