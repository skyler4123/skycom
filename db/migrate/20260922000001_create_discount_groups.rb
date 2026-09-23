class CreateDiscountGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :discount_groups, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.string :prefix

      # --- Calculation config ---
      t.integer :discount_type, null: false
      t.integer :currency
      t.integer :amount_cents
      t.decimal :percentage, precision: 15, scale: 4
      t.integer :max_amount_cents

      # --- Budget & validity ---
      t.integer  :total_budget_cents
      t.integer  :current_spent_cents, default: 0, null: false
      t.integer  :campaign_status, default: 0, null: false
      t.datetime :start_at
      t.datetime :end_at

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :discount_groups, [ :company_id, :campaign_status ]
  end
end
