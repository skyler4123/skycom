class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.references :user, null: false, foreign_key: true
      t.references :parent_company, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.integer :status
      t.integer :kind
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :companies, :discarded_at
  end
end
