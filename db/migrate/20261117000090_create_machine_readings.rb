class CreateMachineReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_readings, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :work_center, null: false, foreign_key: true, type: :uuid

      # --- Reading ---
      t.datetime :recorded_at, null: false
      t.decimal  :usage_units, precision: 15, scale: 4, null: false, default: 0.0
      t.decimal  :output_units, precision: 15, scale: 4, null: false, default: 0.0
      t.jsonb    :metadata, default: {}

      t.timestamps
    end

    add_index :machine_readings, [ :work_center_id, :recorded_at ]
  end
end
