class CreatePricePeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :price_periods, id: :uuid do |t|
      t.references :price_periodable, polymorphic: true, null: false, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.references :price, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
