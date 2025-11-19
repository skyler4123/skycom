class Product < ApplicationRecord
  belongs_to :company
  belongs_to :product_brand
end
