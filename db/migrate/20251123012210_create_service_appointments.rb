class CreateServiceAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :service_appointments, id: :uuid do |t|
      t.references :service, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :duration
      t.datetime :start_at
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :service_appointments, :discarded_at
  end
end
