class CreateDailyActiveLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_active_logs, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.date :log_date, null: false

      t.timestamps
    end

    # Idempotent snapshot key: 1 row per company per calendar date.
    # SyncDailyActiveJob runs every 6 hours; this unique index collapses
    # duplicate inserts so a company can only be billed for 1 active day
    # no matter how many times the job fires in a 24h window.
    add_index :daily_active_logs, %i[ company_id log_date ],
              unique: true,
              name: "idx_daily_active_logs_unique"

    # Optimizes the billing-time query:
    #   WHERE company_id = X AND log_date BETWEEN period_start AND period_end
    add_index :daily_active_logs, :log_date
  end
end
