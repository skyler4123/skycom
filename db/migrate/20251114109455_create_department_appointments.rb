class CreateDepartmentAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :department_appointments, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :department, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at
      t.jsonb :metadata, default: {}
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :department_appointments, [ :appoint_to_type, :appoint_to_id ]
  end
end
