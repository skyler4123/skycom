class PurchaseItem < ApplicationRecord
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  include CategoryConcern
  include PropertyMappingConcern
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :purchase
  belongs_to :category
  belongs_to :property_mapping
end
