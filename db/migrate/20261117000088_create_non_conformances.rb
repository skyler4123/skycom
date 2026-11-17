class CreateNonConformances < ActiveRecord::Migration[8.0]
  def change
    create_table :non_conformances, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :quality_inspection, foreign_key: true, type: :uuid
      t.references :production_order, foreign_key: true, type: :uuid
      t.references :stock_import, foreign_key: true, type: :uuid
      t.references :product, foreign_key: true, type: :uuid

      # --- Defect ---
      t.string  :code
      t.text    :description
      t.integer :severity, null: false, default: 0
      t.integer :disposition, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.datetime :resolved_at

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

    add_index :non_conformances, [ :company_id, :status ]
    add_index :non_conformances, [ :product_id, :severity ]
  end
end
