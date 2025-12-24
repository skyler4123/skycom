class CreatePeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :periods, id: :uuid do |t|
      t.datetime :start_at, null: false
      t.datetime :end_at # Allow nil (forever)

      # Store the offset as an integer (e.g., 7, -5, 0)
      # default: 0 (UTC)
      t.integer :time_zone, default: 0, null: false

      t.timestamps
    end

    # Enforce unique period per start/end/offset combination
    add_index :periods,
              [ :start_at, :end_at, :time_zone ],
              unique: true,
              nulls_not_distinct: true
  end
end
