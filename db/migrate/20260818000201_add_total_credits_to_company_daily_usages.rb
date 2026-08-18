# frozen_string_literal: true

class AddTotalCreditsToCompanyDailyUsages < ActiveRecord::Migration[8.0]
  def change
    add_column :company_daily_usages, :total_credits, :bigint, null: false, default: 0
  end
end
