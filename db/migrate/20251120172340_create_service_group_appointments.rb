class CreateServiceGroupAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :service_group_appointments do |t|
      t.references :service_group, null: false, foreign_key: true
      t.references :appoint_to, polymorphic: true, null: false
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :duration
      t.datetime :start_at
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :service_group_appointments, :discarded_at
  end
end
