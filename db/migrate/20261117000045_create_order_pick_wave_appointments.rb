class CreateOrderPickWaveAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :order_pick_wave_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :pick_wave, null: false, foreign_key: true, type: :uuid

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

    add_index :order_pick_wave_appointments, [ :order_id, :pick_wave_id ], unique: true, name: "idx_order_pick_wave_unique"
  end
end
