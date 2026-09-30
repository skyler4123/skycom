class CreateCalendarEventEquipment < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_event_equipments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_event, null: false, foreign_key: true, type: :uuid
      t.references :calendar_equipment, null: false, foreign_key: true, type: :uuid

      t.string   :role, null: false, default: "primary"
      t.boolean  :required, null: false, default: true
      t.jsonb    :metadata, default: {}

      t.timestamps
    end

    add_index :calendar_event_equipments,
      [ :calendar_event_id, :calendar_equipment_id ], unique: true,
      name: "idx_calendar_event_equipment_uniq"
    add_index :calendar_event_equipments, [ :company_id, :calendar_equipment_id ],
      name: "idx_calendar_event_equipment_resource"
  end
end
