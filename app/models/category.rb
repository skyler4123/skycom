class Category < ApplicationRecord
  belongs_to :company

  has_many :employee_groups, dependent: :nullify
  has_many :employees, dependent: :nullify
  has_many :departments, dependent: :nullify

  validates :name, uniqueness: { scope: :company_id }
end
