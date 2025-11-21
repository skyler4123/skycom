class Cart < ApplicationRecord
  belongs_to :company
  belongs_to :cart_group
end
