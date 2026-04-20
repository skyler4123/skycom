class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string :key
      t.string :value
      t.string :description
      t.string :code
      t.string :permission_resource_name

      t.timestamps
    end
  end
end
