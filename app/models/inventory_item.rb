class InventoryItem < ApplicationRecord
  include TagConcern

  belongs_to :inventory
end
