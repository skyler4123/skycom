class RemovePriceAndPeriodModels < ActiveRecord::Migration[8.0]
  def change
    # Add price_cents to products (replaces the PriceConcern + PriceAppointment pattern)
    add_column :products, :price_cents, :integer, default: 0, null: false

    # Drop price_appointments first (has FKs to prices and periods)
    drop_table :price_appointments

    # Drop period_appointments (has FK to periods)
    drop_table :period_appointments

    # Drop remaining Price/Period tables
    drop_table :prices
    drop_table :periods
  end
end
