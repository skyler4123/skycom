class CreateFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :facilities, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :facilities, :discarded_at
  end
end
