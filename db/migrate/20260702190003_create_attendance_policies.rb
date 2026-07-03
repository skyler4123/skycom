class CreateAttendancePolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_policies, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.integer :allowed_radius_meters, default: 100, null: false
      t.string :allowed_wifi_ssid
      t.boolean :require_photo, default: false, null: false

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end
  end
end
