class CreateShifts < ActiveRecord::Migration[8.0]
  def change
    create_table :shifts, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
