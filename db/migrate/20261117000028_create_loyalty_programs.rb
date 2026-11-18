class CreateLoyaltyPrograms < ActiveRecord::Migration[8.0]
  def change
    create_table :loyalty_programs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Program ---
      t.string  :name, null: false
      t.text    :description
      t.integer :earn_rate_bp, null: false, default: 0
      t.integer :redeem_rate_bp, null: false, default: 0
      t.integer :expires_after_days
      t.boolean :is_active, null: false, default: true

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

    add_index :loyalty_programs, [ :company_id, :name ], unique: true
  end
end
