class CreateStatistics < ActiveRecord::Migration[8.0]
  def change
    create_table :statistics, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :owner, polymorphic: true, null: false, type: :uuid
      t.json :data
      t.datetime :recorded_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :statistics, :recorded_at
  end
end
