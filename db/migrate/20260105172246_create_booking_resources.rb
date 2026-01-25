class CreateBookingResources < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_resources, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :booking_resourceable, polymorphic: true, null: false, type: :uuid
      t.string :name
      t.text :description
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :booking_resources, :discarded_at
  end
end
