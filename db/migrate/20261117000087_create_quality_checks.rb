class CreateQualityChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :quality_checks, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :quality_inspection, null: false, foreign_key: true, type: :uuid

      # --- Measurement ---
      t.string  :name, null: false
      t.string  :characteristic
      t.decimal :min_value, precision: 15, scale: 4
      t.decimal :max_value, precision: 15, scale: 4
      t.decimal :measured_value, precision: 15, scale: 4
      t.integer :result, null: false, default: 0
      t.text    :notes

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :quality_checks, [ :quality_inspection_id, :name ]
  end
end
