class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :booking_resource, null: false, foreign_key: true, type: :uuid
      t.references :price, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: false, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: false, type: :uuid
      t.references :appoint_by, polymorphic: true, null: false, type: :uuid
      t.string :name
      t.text :description
      t.references :price, null: false, foreign_key: true, type: :uuid
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :bookings, :discarded_at
  end
end
