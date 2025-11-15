class CreateRoleAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :role_appointments do |t|
      t.references :role, null: false, foreign_key: true
      t.references :appoint_to, polymorphic: true, null: false
      t.string :name
      t.string :description
      t.integer :status
      t.integer :kind
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :role_appointments, :discarded_at
  end
end
