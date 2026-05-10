class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.jsonb :metadata, default: {}
      t.string :permission_resource_name

      # --- System Fields ---
      t.integer  :lifecycle_status
      t.integer  :workflow_status
      t.integer  :business_type
      t.datetime :expiration_date
      t.datetime :discarded_at,   index: true

      t.timestamps
    end
  end
end
