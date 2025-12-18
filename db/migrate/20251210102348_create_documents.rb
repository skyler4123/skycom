class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents, id: :uuid do |t|
      t.references :document_group, null: false, foreign_key: true, type: :uuid
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
    add_index :documents, :discarded_at
  end
end
