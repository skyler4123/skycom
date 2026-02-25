class InventoryItem < ApplicationRecord
  include TagConcern

  belongs_to :company_group
  belongs_to :branch, optional: true
  belongs_to :inventory
end
