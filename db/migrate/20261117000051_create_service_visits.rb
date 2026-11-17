class CreateServiceVisits < ActiveRecord::Migration[8.0]
  def change
    create_table :service_visits, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.references :project, foreign_key: true, type: :uuid
      t.references :facility, foreign_key: true, type: :uuid
      t.references :assigned_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Visit ---
      t.datetime :scheduled_at, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer  :status, null: false, default: 0
      t.text     :report

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

    add_index :service_visits, [ :company_id, :scheduled_at ]
    add_index :service_visits, [ :assigned_employee_id, :status ]
  end
end
