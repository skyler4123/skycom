# frozen_string_literal: true

# Creates per-company dashboard configuration rows. The first record is the
# dashboard rendered at /companies/:company_id/dashboards; its metadata["blocks"]
# array decides which full-width sections are active (see docs/DASHBOARD_PATTERN.md).
class CreateDashboards < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboards, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.text :description
      t.string :code
      t.string :external_id

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status, null: false, default: 1
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :dashboards, [ :company_id, :name ], unique: true
    add_index :dashboards, [ :company_id, :workflow_status ]
  end
end
