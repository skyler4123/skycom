class CreateBomLines < ActiveRecord::Migration[8.0]
  def change
    create_table :bom_lines, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :bill_of_material, null: false, foreign_key: true, type: :uuid
      t.references :component_product, null: false, foreign_key: { to_table: :products }, type: :uuid

      # --- Component ---
      t.decimal :quantity, precision: 15, scale: 4, null: false, default: 1.0
      t.integer :scrap_bp, null: false, default: 0
      t.integer :position, null: false, default: 1

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

    add_index :bom_lines, [ :bill_of_material_id, :position ], unique: true
  end
end
