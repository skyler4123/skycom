class CreateWorkflows < ActiveRecord::Migration[8.0]
  def change
    create_table :workflows, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid, index: { unique: true }

      # --- Identity ---
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.integer :process_type

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

    add_index :workflows, [ :company_id, :process_type ]
  end
end
