class CreateEmployeeGroupAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_group_appointments do |t|
      t.references :employee_group, null: false, foreign_key: true
      t.references :appoint_to, polymorphic: true, null: false
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end
