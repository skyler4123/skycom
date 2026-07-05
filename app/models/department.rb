class Department < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  attribute :metadata, :jsonb, default: {}
  attribute :currency_code, :integer, default: 840
  attribute :country_code, :integer, default: 1
  attribute :timezone, :string, default: "UTC"

  include AddressConcern
  include TagConcern
  include Department::ImageConcern

  enum :business_type, {
    sales: 0,
    marketing: 1,
    operations: 2,
    finance: 3,
    human_resources: 4,
    information_technology: 5,
    customer_service: 6,
    research_and_development: 7,
    legal: 8,
    administrative: 9
  }, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :category
  belongs_to :property_mapping

  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments

  has_many :department_appointments, dependent: :destroy
  has_many :employees, through: :department_appointments, source: :appoint_to, source_type: "Employee"
end
