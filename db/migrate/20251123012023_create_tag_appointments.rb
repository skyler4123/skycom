class CreateTagAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :tag_appointments, id: :uuid do |t|
      t.references :tag, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid
      t.string :value
      t.string :description

      t.timestamps
    end
    add_index :tag_appointments, [ :appoint_to_type, :appoint_to_id ]
  end
end
