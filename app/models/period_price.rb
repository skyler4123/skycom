class PeriodPrice < ApplicationRecord
  belongs_to :period_priceable, polymorphic: true
  belongs_to :period
  belongs_to :price
end
