class CreateDepartments < ActiveRecord::Migration[8.0]
  def change
    create_table :departments, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :email,           null: false, index: { unique: true }
      t.string :name
      t.string :description
      t.string :code

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
  end
end
