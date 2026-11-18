class CreateLoyaltyEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :loyalty_entries, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.references :loyalty_program, null: false, foreign_key: true, type: :uuid

      # --- Movement ---
      t.integer :points, null: false, default: 0
      t.integer :direction, null: false, default: 0
      t.string  :source_type
      t.uuid    :source_id
      t.date    :expires_on
      t.string  :note

      t.timestamps
    end

    add_index :loyalty_entries, [ :company_id, :customer_id, :created_at ]
  end
end
