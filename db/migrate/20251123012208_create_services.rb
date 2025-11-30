class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :duration
      t.datetime :start_at
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :services, :discarded_at
  end
end
