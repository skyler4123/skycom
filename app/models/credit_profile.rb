# frozen_string_literal: true

# CreditProfile — Atomic purpose: the credit limit and order-hold decision for one customer.
#
# Why it exists: selling on account means the company is lending money; without a stored limit and a hold switch, an order is approved purely by whoever is at the till. One row per customer keeps the decision reviewable and dated instead of being buried in a note.
# How it works: limit in integer cents plus `hold_orders` as the operational switch, so a review can raise the limit without unblocking a customer who still has overdue invoices. `reviewed_at`/`reviewed_by_employee` force the decision to have an owner.
# Main associations: belongs_to :company, :customer, :reviewed_by_employee (optional).
class CreditProfile < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :customer
  belongs_to :reviewed_by_employee, class_name: "Employee", optional: true

  # --- Scopes ---
  scope :holding, -> { where(hold_orders: true) }

  # --- Validations ---
  validates :limit_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :customer_id, uniqueness: { scope: :company_id }

  # --- Methods ---
  def exceeded_by?(open_balance_cents)
    limit_cents.to_i.positive? && open_balance_cents.to_i > limit_cents.to_i
  end
end
