class Category < ApplicationRecord
  belongs_to :company_group

  has_many :employee_groups
  has_many :employees


  validates :name, uniqueness: { scope: :company_group_id }
end
