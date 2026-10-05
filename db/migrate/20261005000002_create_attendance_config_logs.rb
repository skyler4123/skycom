class CreateAttendanceConfigLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_config_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :attendance_config, null: true, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: true, foreign_key: true, type: :uuid
      t.integer :action, null: false
      t.string :employee_name
      t.string :branch_name
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :allowed_radius_meters
      t.string :allowed_wifi_ssid
      t.boolean :require_photo
      t.integer :resolution_strategy
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :attendance_config_logs, [ :company_id, :attendance_config_id, :created_at ],
      name: "idx_attendance_config_logs_on_config_time"
    add_index :attendance_config_logs, [ :company_id, :created_at ],
      name: "idx_attendance_config_logs_on_company_time"
  end
end
