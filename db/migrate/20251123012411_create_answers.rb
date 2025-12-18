class CreateAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :answers, id: :uuid do |t|
      t.references :question, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :answers, :discarded_at
  end
end
