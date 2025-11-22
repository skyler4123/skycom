class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses, id: :uuid do |t|
      t.string :alpha2
      t.string :alpha3
      t.string :continent
      t.string :nationality
      t.string :region
      t.decimal :longitude
      t.decimal :latitude
      t.integer :level_total
      t.string :level_1
      t.string :level_2
      t.string :level_3
      t.string :level_4
      t.string :level_5
      t.string :level_6
      t.string :level_7
      t.string :level_8
      t.string :level_9
      t.string :level_10
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :addresses, :alpha2
    add_index :addresses, :alpha3
    add_index :addresses, :continent
    add_index :addresses, :nationality
    add_index :addresses, :region
    add_index :addresses, :level_1
    add_index :addresses, :level_2
    add_index :addresses, :level_3
    add_index :addresses, :level_4
    add_index :addresses, :level_5
    add_index :addresses, :level_6
    add_index :addresses, :level_7
    add_index :addresses, :level_8
    add_index :addresses, :level_9
    add_index :addresses, :level_10
  end
end
