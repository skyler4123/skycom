class Invoice < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern

  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    sales: 0,
    service: 1,
    subscription: 2
  }
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :payment_status, { unpaid: 0, paid: 1, voided: 2 }, default: :unpaid
  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :order
  belongs_to :category
  belongs_to :property_mapping

  has_many :transactions, dependent: :destroy
  has_many :discounts, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :currency, presence: true
  validates :code, presence: true, uniqueness: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :business_type, presence: true

  # --- Callbacks ---
  # Discounts follow the invoice payment lifecycle (docs/DISCOUNTS.md) — the
  # commerce-chain mirror of CompanyInvoice#complete_order_if_paid!.
  after_update :sync_discount_state, if: :saved_change_to_payment_status?

  def total_price_cents
    price_cents
  end

  private

  # Became paid → consume the pending code reserved on the order; left paid
  # (unpaid/voided) → revert used codes and refund the campaign budget
  # (docs/DISCOUNTS.md §5).
  def sync_discount_state
    if paid?
      order.discounts.status_pending.find_each { |discount| discount.consume!(invoice: self) }
    else
      discounts.status_used.find_each(&:revert!)
    end
  end
end
