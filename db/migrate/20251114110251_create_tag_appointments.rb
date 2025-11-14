class CreateTagAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :tag_appointments do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :appoint_to, polymorphic: true, null: false
      t.string :value
      t.string :description

      t.timestamps
    end
  end
end
