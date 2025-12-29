class CreateSystems < ActiveRecord::Migration[8.0]
  def change
    create_table :systems, id: :uuid do |t|
      # Identity
      t.string :name, null: false, default: "System"
      t.string :code, null: false, comment: "System"

      # Financials (Optional but recommended)
      # Using integers for money (cents) is safer than floats
      t.integer :balance_cents, default: 0, null: false
      t.string :currency, default: 'USD', null: false
      t.integer :country_code

      # Status
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    # Ensure the code is unique so you can't have duplicate Platform accounts
    add_index :systems, :name, unique: true
  end
end
