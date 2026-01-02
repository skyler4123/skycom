class PurchaseItem < ApplicationRecord
  include TagConcern

  belongs_to :purchase
end
