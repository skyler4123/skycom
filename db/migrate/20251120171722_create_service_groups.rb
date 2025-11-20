class CreateServiceGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :service_groups do |t|
      t.references :company, null: false, foreign_key: true
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
    add_index :service_groups, :discarded_at
  end
end
