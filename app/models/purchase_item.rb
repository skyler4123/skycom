class PurchaseItem < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :purchase
  belongs_to :category
  belongs_to :property_mapping
end
