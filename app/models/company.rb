class Company < ApplicationRecord
  belongs_to :user

  has_many :employees, dependent: :destroy
  has_many :employee_groups, dependent: :destroy

  validates :name, uniqueness: { scope: :user_id }
end
