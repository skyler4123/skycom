class CreateReservationAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :reservation_appointments, id: :uuid do |t|
      t.references :reservations, null: false, foreign_key: true, type: :uuid

      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type

      t.timestamps
    end
  end
end
