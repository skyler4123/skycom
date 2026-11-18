class CreateFiscalPeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :fiscal_periods, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Period ---
      t.integer :fiscal_year, null: false
      t.integer :period_no,   null: false
      t.string  :name
      t.date    :starts_on,   null: false
      t.date    :ends_on,     null: false
      t.integer :status,      null: false, default: 0

      # --- Close ---
      t.datetime :closed_at
      t.references :closed_by_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :fiscal_periods, [ :company_id, :fiscal_year, :period_no ], unique: true
    add_index :fiscal_periods, [ :company_id, :starts_on, :ends_on ]
  end
end
