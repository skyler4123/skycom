class PricePeriod < ApplicationRecord
  belongs_to :price_periodable, polymorphic: true
  belongs_to :period
  belongs_to :price
end
