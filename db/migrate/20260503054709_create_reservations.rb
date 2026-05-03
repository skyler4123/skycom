class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :reservations, id: :uuid do |t|
      t.string :name
      t.string :code, null: false

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type

      t.timestamps
    end
  end
end
