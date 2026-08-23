class PurchaseItem < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include TagConcern
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :purchase
  belongs_to :category
  belongs_to :property_mapping
end
