class OrderGroup < ApplicationRecord
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :customer
end
