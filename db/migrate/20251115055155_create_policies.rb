class CreatePolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :policies do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.string :resource
      t.string :action
      t.integer :status
      t.integer :kind
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :policies, :discarded_at
  end
end
