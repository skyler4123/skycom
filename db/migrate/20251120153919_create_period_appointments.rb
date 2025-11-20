class CreatePeriodAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :period_appointments do |t|
      t.references :period, null: false, foreign_key: true
      t.references :appoint_to, polymorphic: true, null: false
      t.string :name
      t.string :description
      t.string :code
      t.string :value

      t.timestamps
    end
  end
end
