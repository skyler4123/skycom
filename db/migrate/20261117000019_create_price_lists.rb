class CreatePriceLists < ActiveRecord::Migration[8.0]
  def change
    create_table :price_lists, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :customer_group, foreign_key: true, type: :uuid

      # --- Price book ---
      t.string  :name, null: false
      t.text    :description
      t.integer :currency, default: 840
      t.boolean :is_default, null: false, default: false
      t.date    :effective_from
      t.date    :effective_to

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

    add_index :price_lists, [ :company_id, :name ], unique: true
  end
end
