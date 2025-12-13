class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings, id: :uuid do |t|
      t.references :setting_group, null: false, foreign_key: true, type: :uuid
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.json :content
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :settings, :discarded_at
  end
end
