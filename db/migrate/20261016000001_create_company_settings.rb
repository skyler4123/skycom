class CreateCompanySettings < ActiveRecord::Migration[8.0]
  def change
    create_table :company_settings, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code

      # --- Secure Credential Columns (Rails built-in encryption via `encrypts`) ---
      t.text :credential_1
      t.text :credential_2
      t.text :credential_3

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status, default: 0, null: false
      t.integer :business_type, null: false
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :company_settings, [ :company_id, :business_type ]
    add_index :company_settings, [ :company_id, :name ], unique: true, name: "idx_company_settings_name_uniq"
    add_index :company_settings, [ :company_id, :business_type ],
      unique: true,
      where: "workflow_status = 1 AND discarded_at IS NULL",
      name: "idx_company_settings_single_active"
  end
end
