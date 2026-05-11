class CreateSystems < ActiveRecord::Migration[8.0]
  def change
    create_table :systems, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.string :email

      t.string :name, null: false, default: "System"
      t.string :code, null: false, comment: "System"

      t.integer :balance_cents, default: 0, null: false
      t.integer :currency_code
      t.integer :country_code

      t.boolean :active, default: true, null: false

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

    add_index :systems, :name, unique: true
  end
end
