class DiscountGroup < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  normalizes :prefix, with: -> { _1.strip.upcase.presence }

  # --- Enums ---
  enum :discount_type, { fixed_amount: 0, percentage: 1 }, prefix: true
  enum :campaign_status, { draft: 0, active: 1, paused: 2, exhausted: 3 }, default: :draft, prefix: true
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  has_many :discounts, dependent: :destroy

  # --- Scopes ---
  scope :currently_active, -> {
    where(campaign_status: :active)
      .where("start_at <= :now AND end_at >= :now", now: Time.current)
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :discount_type, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }, if: :discount_type_fixed_amount?
  validates :percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, if: :discount_type_percentage?
  validates :max_amount_cents, :total_budget_cents, numericality: { greater_than: 0 }, allow_nil: true
  validates :current_spent_cents, numericality: { greater_than_or_equal_to: 0 }
  validate :end_at_after_start_at

  # --- Methods ---
  def currently_active?
    campaign_status_active? && start_at.present? && end_at.present? &&
      Time.current.between?(start_at, end_at)
  end

  def budget_exhausted_with?(amount_cents)
    return false if total_budget_cents.nil?

    current_spent_cents + amount_cents > total_budget_cents
  end

  # Row-locked budget mutation; flips exhausted at the cap and reactivates when
  # a refund drops spend back under it (docs/DISCOUNTS.md §5).
  def adjust_spent!(delta_cents)
    with_lock do
      self.current_spent_cents += delta_cents
      if total_budget_cents && current_spent_cents >= total_budget_cents
        self.campaign_status = :exhausted
      elsif campaign_status_exhausted?
        self.campaign_status = :active
      end
      save!
    end
  end

  private

  def end_at_after_start_at
    return if start_at.blank? || end_at.blank? || end_at > start_at

    errors.add(:end_at, "must be after start_at")
  end
end
