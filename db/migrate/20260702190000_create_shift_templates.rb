class CreateShiftTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :shift_templates, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :grace_period_minutes, default: 15, null: false
      t.integer :unpaid_break_minutes, default: 60, null: false
      t.string :policy_type, default: "fixed", null: false
      t.integer :full_day_minutes, default: 480, null: false
      t.time :core_start_time
      t.time :core_end_time
      t.string :description

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
