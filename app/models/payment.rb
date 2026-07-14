class Payment < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  attribute :metadata, :jsonb, array: true, default: []
  enum :country_code, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency_code, CURRENCIE_CODES, prefix: true, default: :usd

  include TagConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :invoice
  belongs_to :category
  belongs_to :property_mapping

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    standard_payment: 0,
    prepayment: 1,
    final_payment: 2
  }

  # NOTE: payment_method and amount columns were removed from schema
  # enum :payment_method, {
  #   credit_card: 0,
  #   bank_transfer: 1,
  #   paypal: 2,
  #   cash: 3
  # }

  # --- Validations ---
  validates :currency_code, presence: true

  # NOTE: amount and payment_method columns were removed from schema
  # validates :amount, presence: true, numericality: { greater_than: 0 }
  # validates :payment_method, presence: true
end
