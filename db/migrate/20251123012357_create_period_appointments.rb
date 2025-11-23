class CreatePeriodAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :period_appointments, id: :uuid do |t|
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: false, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: false, type: :uuid
      t.references :appoint_by, polymorphic: true, null: false, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.string :value

      t.timestamps
    end
  end
end
