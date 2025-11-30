class OrderGroup < ApplicationRecord
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :customer
end
