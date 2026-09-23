class Discount < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  normalizes :code, with: -> { _1.strip.upcase }

  # --- Enums ---
  enum :status, { unused: 0, pending: 1, used: 2, expired: 3 }, default: :unused, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :discount_group
  belongs_to :order, optional: true
  belongs_to :invoice, optional: true
  belongs_to :customer, optional: true
  belongs_to :employee, optional: true

  # --- Validations ---
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :same_company_as_discount_group

  # --- Methods ---
  def compute_amount_cents(subtotal_cents)
    group = discount_group
    if group.discount_type_fixed_amount?
      [ group.amount_cents, subtotal_cents ].min
    else
      calculated = (subtotal_cents * group.percentage / 100.0).round
      group.max_amount_cents ? [ calculated, group.max_amount_cents ].min : calculated
    end
  end

  # Reservation phase: binds the code to the order. Consumed only when the
  # resulting Invoice becomes paid (Invoice#sync_discount_state).
  def reserve!(order:, employee:, amount_cents:)
    update!(status: :pending, order: order, employee: employee,
      customer: order.customer, amount_cents: amount_cents,
      invoice: nil, used_at: nil)
  end

  def consume!(invoice:, used_at: Time.current)
    update!(status: :used, invoice: invoice, used_at: used_at)
    discount_group.adjust_spent!(amount_cents)
  end

  # Pending → unused (cancel abandoned payment / initiation failure). Used
  # codes revert through #revert! only.
  def release!
    return false unless status_pending?

    update!(status: :unused, order: nil, invoice: nil, customer: nil,
      employee: nil, amount_cents: nil, used_at: nil)
    true
  end

  # Refund path: give the consumed amount back to the campaign budget and
  # return the code to the pool.
  def revert!
    return false unless status_used?

    discount_group.adjust_spent!(-amount_cents)
    update!(status: :unused, order: nil, invoice: nil, customer: nil,
      employee: nil, amount_cents: nil, used_at: nil)
    true
  end

  private

  def same_company_as_discount_group
    return if company.nil? || discount_group.nil?
    return if company_id == discount_group.company_id

    errors.add(:discount_group, "must belong to the same company")
  end
end
