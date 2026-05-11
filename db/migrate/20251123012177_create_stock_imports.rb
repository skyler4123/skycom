class CreateStockImports < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_imports, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid

      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: true, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid

      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :quantity

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
  end
end
