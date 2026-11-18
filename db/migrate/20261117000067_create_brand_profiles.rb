class CreateBrandProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :brand_profiles, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :logo_stored_file, foreign_key: { to_table: :stored_files }, type: :uuid

      # --- Brand ---
      t.string  :domain, null: false
      t.string  :display_name
      t.string  :primary_color
      t.string  :email_from
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

    add_index :brand_profiles, :domain, unique: true
    add_index :brand_profiles, [ :company_id, :is_active ]
  end
end
