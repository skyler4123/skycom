class CreatePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :prices, id: :uuid do |t|
      # High precision for amount (same as before)
      t.decimal :amount, precision: 19, scale: 4, null: false

      # Changed to integer for enum usage.
      # default: 0 usually maps to your primary currency (e.g., USD)
      t.integer :currency, default: 0, null: false

      t.timestamps
    end

    # Unique index now uses the integer currency column
    add_index :prices, [ :amount, :currency ], unique: true
  end
end
