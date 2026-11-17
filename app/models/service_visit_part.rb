# frozen_string_literal: true

# ServiceVisitPart — Atomic purpose: one part or product consumed on a service visit, with its price at the time of use.
#
# Why it exists: van stock and the customer invoice must both reconcile; a part used on site is a sale and a stock movement at once, and the price charged has to be frozen or a later catalog change would alter an invoice the client already received.
# How it works: child of the visit; `stock` identifies the exact row consumed when known. Quantity and price are integer units/cents. The stock movement itself is written by the existing ledger, not here.
# Main associations: belongs_to :company, :service_visit, :product, :stock (optional).
class ServiceVisitPart < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :service_visit
  belongs_to :product
  belongs_to :stock, optional: true

  # --- Validations ---
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # --- Methods ---
  def total_cents
    quantity.to_i * price_cents.to_i
  end
end
