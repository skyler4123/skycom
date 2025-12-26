class CreateStatistics < ActiveRecord::Migration[8.0]
  def change
    create_table :statistics, id: :uuid do |t|
      t.references :owner, polymorphic: true, null: false, type: :uuid
      t.string :name
      t.string :description
      t.json :data
      t.datetime :recorded_at

      t.timestamps
    end
    add_index :statistics, :recorded_at
  end
end
