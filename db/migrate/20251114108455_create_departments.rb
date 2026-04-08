class CreateDepartments < ActiveRecord::Migration[8.0]
  def change
    create_table :departments, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :email,           null: false, index: { unique: true }
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :departments, :discarded_at
  end
end
