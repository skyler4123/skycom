class Category < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company

  has_one :property_mapping, dependent: :destroy

  after_create :create_default_property_mapping
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

  private

  def create_default_property_mapping
    create_property_mapping!(company: company, name: "#{name} mappings")
  end
end
