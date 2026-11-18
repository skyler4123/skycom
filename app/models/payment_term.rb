# frozen_string_literal: true

# PaymentTerm — Atomic purpose: a named due-date and early-payment-discount rule (Net 30, 2/10 Net 30) applied to invoices and bills.
#
# Why it exists: due dates, ageing buckets and dunning levels are all derived from terms; hardcoding '30 days' per feature means a company that negotiates Net 45 has to change code. One row per term lets sales and procurement use different terms without new columns.
# How it works: `net_days` sets the due date from the document date; `discount_days`/`discount_bp` express the settlement discount in basis points. `is_default` is a per-company convenience flag, not a uniqueness constraint, so a company can have several active terms. Pure master data — no workflow.
# Main associations: belongs_to :company. Referenced by invoices, orders, purchases, customers and suppliers.
class PaymentTerm < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company

  # --- Scopes ---
  scope :default_term, -> { where(is_default: true) }
  scope :ordered, -> { order(:net_days, :name) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :company_id }
  validates :net_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :discount_days, :discount_bp, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # --- Methods ---
  def due_date_for(document_date)
    document_date.to_date + net_days.to_i.days
  end

  def discount_deadline_for(document_date)
    return nil if discount_days.blank?

    document_date.to_date + discount_days.to_i.days
  end
end
