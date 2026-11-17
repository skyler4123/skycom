class CreateProjectTimeEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :project_time_entries, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.references :task, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :invoice, foreign_key: true, type: :uuid

      # --- Time ---
      t.date    :worked_on, null: false
      t.integer :minutes, null: false, default: 0
      t.boolean :billable, null: false, default: true
      t.bigint  :rate_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.integer :status, null: false, default: 0
      t.text    :notes

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

    add_index :project_time_entries, [ :company_id, :project_id, :worked_on ]
    add_index :project_time_entries, [ :employee_id, :worked_on ]
  end
end
