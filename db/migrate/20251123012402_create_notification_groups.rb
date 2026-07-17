class CreateNotificationGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_groups, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: false, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :email, null: true, index: { unique: true }
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.string :phone_number
      t.integer :currency
      t.integer :country
      t.integer  :timezone

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
  end
end
