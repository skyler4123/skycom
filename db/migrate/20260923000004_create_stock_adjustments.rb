class CreateStockAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_adjustments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: false, foreign_key: true, type: :uuid

      t.string  :email
      t.string  :name
      t.text    :description
      t.string  :code, index: true
      t.string  :phone_number
      t.string  :reason
      t.integer :direction, null: false
      t.integer :currency, default: 0
      t.integer :country, default: 0
      t.integer :timezone, default: 0

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :stock_adjustments, [ :company_id, :workflow_status ]
  end
end
