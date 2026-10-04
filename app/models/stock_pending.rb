# StockPending — Atomic purpose: the owner-less pending-hold record.
# One row = one promise of `quantity` units on a Stock in a Warehouse.
# Lifecycle runs on `workflow_status`: draft (ineffective) → holding set
# (pending/in_progress/initiated) → released set
# (completed/cancelled/received/shipped/failed/refunded) with `released_at`
# stamped on exit. Pending moves ONLY through StockTransaction hold/release
# ledger rows (see StockTransaction); this model never writes Stock columns.
class StockPending < ApplicationRecord
  HOLDING_STATUSES = %w[pending in_progress initiated].freeze
  CODE_PREFIX = "STKPD".freeze

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :business_type, {
    pos: 0,
    transfer: 1,
    manual: 2,
    event: 3
  }, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :warehouse
  belongs_to :stock
  belongs_to :product
  has_many :stock_transactions, as: :appoint_for, dependent: :restrict_with_error

  # --- Validations ---
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :workflow_status, presence: true
  validate :same_company_across_links
  validate :warehouse_matches_stock
  validate :product_matches_stock
  validate :released_at_matches_status

  before_validation :stamp_status_changed_at, on: :create
  before_destroy :prevent_destroy_if_holding

  def holding?
    HOLDING_STATUSES.include?(workflow_status)
  end

  def release!
    return false unless holding?

    update!(workflow_status: :completed, released_at: Time.current, status_changed_at: Time.current)
    true
  end

  def cancel!
    return false unless holding?

    update!(workflow_status: :cancelled, released_at: Time.current, status_changed_at: Time.current)
    true
  end

  private

  def same_company_across_links
    ids = [ company_id, warehouse&.company_id, stock&.company_id, product&.company_id ].compact.uniq
    errors.add(:company, "must match warehouse/stock/product company") if ids.size > 1
  end

  def warehouse_matches_stock
    return if warehouse_id.blank? || stock.blank?

    errors.add(:warehouse, "must equal stock warehouse") unless warehouse_id == stock.warehouse_id
  end

  def product_matches_stock
    return if product_id.blank? || stock.blank?

    errors.add(:product, "must equal stock product") unless product_id == stock.product_id
  end

  def released_at_matches_status
    if holding? || workflow_status == "draft"
      errors.add(:released_at, "must be blank while holding") if released_at.present?
    elsif released_at.blank?
      errors.add(:released_at, "must be set once released")
    end
  end

  def stamp_status_changed_at
    self.status_changed_at ||= Time.current
  end

  def prevent_destroy_if_holding
    return unless holding?

    errors.add(:base, "Cannot destroy a holding stock pending. Release or cancel it first.")
    throw(:abort)
  end
end
