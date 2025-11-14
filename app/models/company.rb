class Company < ApplicationRecord
  belongs_to :user
  belongs_to :parent_company
end
