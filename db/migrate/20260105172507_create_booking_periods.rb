class CreateBookingPeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_periods, id: :uuid do |t|
      t.references :booking_resource, null: false, foreign_key: true, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
