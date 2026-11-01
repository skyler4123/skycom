# frozen_string_literal: true

# Creates the configurable KPI rules. One row is one rule: metric + target +
# weight + period + optional employee scope. Scores are computed on demand by
# Kpi::ScorecardService / Kpi::LeaderboardService (pure visibility, no snapshots).
class CreateKpiConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :kpi_configs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
      t.references :branch, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
      t.references :department, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
      t.references :role, null: true, foreign_key: { on_delete: :nullify }, type: :uuid

      t.string :name, null: false
      t.text :description
      t.string :metric_key, null: false
      t.integer :direction, null: false, default: 0
      t.integer :period_type, null: false, default: 0
      t.decimal :target_value, precision: 15, scale: 2
      t.decimal :weight, precision: 8, scale: 2, null: false, default: 1

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :kpi_configs, [ :company_id, :workflow_status ]
    add_index :kpi_configs, [ :company_id, :name ], unique: true
  end
end
