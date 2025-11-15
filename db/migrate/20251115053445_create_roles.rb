class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.integer :status
      t.integer :kind
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :roles, :discarded_at
  end
end
