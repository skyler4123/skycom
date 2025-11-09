class Employee < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :company

  validates :name, uniqueness: { scope: :company_id }
end
