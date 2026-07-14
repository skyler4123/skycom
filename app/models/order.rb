class Order < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  attribute :metadata, :jsonb, array: true, default: []
  enum :country_code, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc

  include TagConcern
  include MeteringConcern

  metered_as :orders

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :customer, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :invoices, dependent: :destroy
  has_many :order_appointments, dependent: :destroy
  has_many :products, through: :order_appointments, source: :appoint_to, source_type: "Product"
  has_many :services, through: :order_appointments, source: :appoint_to, source_type: "Service"


  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :currency_code, CURRENCIE_CODES, prefix: true, default: :usd
  enum :business_type, {
    online: 0,
    in_store: 1,
    phone: 2
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :currency_code, presence: true

  validates :business_type, presence: true
end
