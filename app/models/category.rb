class Category < ApplicationRecord
  belongs_to :company_group

  has_many :employee_groups, dependent: :nullify
  has_many :employees, dependent: :nullify


  validates :name, uniqueness: { scope: :company_group_id }
end
