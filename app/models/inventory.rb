class Inventory < ApplicationRecord
  belongs_to :company_group
  belongs_to :company, optional: true
end
