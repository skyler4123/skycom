class CreateCalendarEventPractitioners < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_event_practitioners, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_event, null: false, foreign_key: true, type: :uuid
      t.references :calendar_practitioner, null: false, foreign_key: true, type: :uuid

      t.string   :role, null: false, default: "lead"
      t.boolean  :required, null: false, default: true
      t.jsonb    :metadata, default: {}

      t.timestamps
    end

    add_index :calendar_event_practitioners,
      [ :calendar_event_id, :calendar_practitioner_id ], unique: true,
      name: "idx_calendar_event_practitioners_uniq"
    add_index :calendar_event_practitioners, [ :company_id, :calendar_practitioner_id ],
      name: "idx_calendar_event_practitioners_resource"
  end
end
