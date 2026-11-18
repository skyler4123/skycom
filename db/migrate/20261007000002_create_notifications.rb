class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.text :description
      t.integer :severity, default: 0, null: false
      t.string :url

      # --- Deep link & grouping ---
      t.string :subject_type
      t.uuid :subject_id
      t.string :group_key
      t.datetime :expires_at

      t.string :external_id, index: true

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

    add_index :notifications, [ :company_id, :created_at ]
    add_index :notifications, [ :subject_type, :subject_id ]
  end
end
