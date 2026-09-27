class Customer < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include RoleConcern
  include AddressConcern
  include TagConcern
  include MembershipConcern
  include ReservationConcern
  include Customer::ImageConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    individual: 0,
    small_business: 1,
    enterprise: 2
  }
  # --- Associations ---
  belongs_to :user, optional: true
  belongs_to :company, optional: true
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :orders, dependent: :destroy
  has_many :customer_customer_group_appointments, dependent: :destroy
  has_many :customer_groups, through: :customer_customer_group_appointments

  has_many :customer_role_appointments, dependent: :destroy
  has_many :roles, through: :customer_role_appointments

  has_many :customer_service_appointments, dependent: :destroy
  has_many :services, through: :customer_service_appointments

  has_many :customer_employee_appointments, dependent: :destroy
  has_many :employees, through: :customer_employee_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }

  validates :business_type, presence: true
end
