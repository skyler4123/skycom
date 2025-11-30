class CreatePeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :periods, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :duration
      t.datetime :start_at
      t.datetime :end_at
      t.datetime :expire_at
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :periods, :discarded_at
  end
end
