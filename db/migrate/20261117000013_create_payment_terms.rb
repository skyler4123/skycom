class CreatePaymentTerms < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_terms, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Terms ---
      t.string  :name, null: false
      t.text    :description
      t.integer :net_days, null: false, default: 0
      t.integer :discount_days
      t.integer :discount_bp
      t.boolean :is_default, null: false, default: false

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

    add_index :payment_terms, [ :company_id, :name ], unique: true
  end
end
