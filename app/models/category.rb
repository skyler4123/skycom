class Category < ApplicationRecord
  belongs_to :company_group

  has_many :category_appointments

  validates :name, uniqueness: { scope: :company_group_id }
end
