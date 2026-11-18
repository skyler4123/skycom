class CreateBillOfMaterials < ActiveRecord::Migration[8.0]
  def change
    create_table :bill_of_materials, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid

      # --- Recipe ---
      t.string  :name
      t.string  :version, null: false, default: "1"
      t.integer :output_quantity, null: false, default: 1
      t.integer :status, null: false, default: 0
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

    add_index :bill_of_materials, [ :company_id, :product_id, :version ], unique: true, name: "idx_bom_version_unique"
  end
end
