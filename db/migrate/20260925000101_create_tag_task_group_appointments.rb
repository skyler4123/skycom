class CreateTagTaskGroupAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :tag_task_group_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :tag, null: false, foreign_key: { to_table: :tags }, type: :uuid
      t.references :task_group, null: false, foreign_key: { to_table: :task_groups }, type: :uuid
      t.string :value
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name
      t.timestamps
    end
    add_index :tag_task_group_appointments, [ :company_id, :tag_id, :task_group_id ], unique: true, name: "idx_tag_task_group_appointments_uniq"
  end
end
