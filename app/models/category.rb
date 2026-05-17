class Category < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company

  has_many :employee_groups, dependent: :nullify
  has_many :employees, dependent: :nullify
  has_many :departments, dependent: :nullify
  has_many :products, dependent: :nullify
  has_many :services, dependent: :nullify
  has_many :branches, dependent: :nullify
  has_many :brands, dependent: :nullify
  has_many :customers, dependent: :nullify
  has_many :facilities, dependent: :nullify

  validates :name, uniqueness: { scope: [ :company_id, :resource_name ] }
end
