class CreateTimezones < ActiveRecord::Migration[8.0]
  def change
    create_table :timezones, id: :uuid do |t|
      t.string :name
      t.string :description
      t.integer :utc_offset

      t.timestamps
    end
  end
end
