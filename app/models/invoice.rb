class Invoice < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  attribute :metadata, :jsonb, array: true, default: []
  enum :country_code, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc

  include TagConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :order
  belongs_to :category
  belongs_to :property_mapping

  has_many :payments, dependent: :destroy

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    sales: 0,
    service: 1,
    subscription: 2
  }

  enum :currency_code, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :currency_code, presence: true
  validates :code, presence: true, uniqueness: true
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :business_type, presence: true
end
