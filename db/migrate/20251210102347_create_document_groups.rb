class CreateDocumentGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :document_groups, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :title
      t.json :content
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :document_groups, :discarded_at
  end
end
