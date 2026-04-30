class DropPeriodPrices < ActiveRecord::Migration[8.0]
  def up
    drop_table :period_prices
  end

  def down
    create_table :period_prices, id: :uuid do |t|
      t.string "period_priceable_type", null: false
      t.uuid "period_priceable_id", null: false
      t.uuid "period_id", null: false
      t.uuid "price_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false

      t.index ["period_id"], name: "index_period_prices_on_period_id"
      t.index ["period_priceable_type", "period_priceable_id"], name: "index_period_prices_on_period_priceable"
      t.index ["price_id"], name: "index_period_prices_on_price_id"
    end
  end
end