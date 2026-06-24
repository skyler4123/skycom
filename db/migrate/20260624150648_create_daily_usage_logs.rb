class CreateDailyUsageLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_usage_logs, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :billing_resource, null: false, foreign_key: true, type: :uuid

      t.integer :usage_count, default: 0, null: false
      t.date    :log_date, null: false

      t.timestamps
    end

    # This composite index is critical. It optimizes the query:
    # WHERE company_id = X AND billing_resource_id = Y AND log_date BETWEEN Start AND End
    add_index :daily_usage_logs, [ :company_id, :billing_resource_id, :log_date ],
              name: "idx_daily_usage_lookup"
  end
end
