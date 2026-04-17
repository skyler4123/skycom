class CreatePolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :policies, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.string :resource
      t.string :action
      t.jsonb :tag_conditions, default: {}
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :policies, :discarded_at
  end
end
