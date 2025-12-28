class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses, id: :uuid do |t|
      # Standard Address Fields
      t.string :line_1, null: false
      t.string :line_2                    # Optional (Apt, Suite, Unit)
      t.string :city, null: false
      t.string :state_or_province         # Optional (some countries don't use states)
      t.string :postal_code               # Optional (some places don't have zips)
      t.string :country_code, limit: 2, null: false # ISO 3166-1 alpha-2 (e.g., "US", "VN")

      # The Uniqueness Enforcer
      # Stores a hash (SHA256) of the fields above
      t.string :fingerprint, null: false

      t.timestamps
    end

    # Fast, simple unique constraint on the single fingerprint column
    add_index :addresses, :fingerprint, unique: true
  end
end
