class InventoryItem < ApplicationRecord
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :inventory
end
