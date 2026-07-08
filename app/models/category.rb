class Category < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company, touch: true

  has_many :property_mappings, dependent: :destroy
  has_many :table_configs, dependent: :destroy

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
  has_many :stocks, dependent: :nullify

  validates :name, uniqueness: { scope: [ :company_id, :resource_name ] }

  def default_property_mapping
    property_mappings.first
  end

  def default_table_config
    table_configs.first
  end

  private

  def create_default_property_mapping
    property_mappings.create!(company: company, name: "#{name} mappings")
  end
end
