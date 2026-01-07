class CreatePeriodPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :period_prices, id: :uuid do |t|
      t.references :period_priceable, polymorphic: true, null: false, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.references :price, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
