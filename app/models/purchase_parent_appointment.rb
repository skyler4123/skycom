# frozen_string_literal: true

# PurchaseParentAppointment — Atomic purpose: links a purchase document to the document it came from (RFQ → vendor response, blanket order → call-off).
#
# Why it exists: an RFQ has many answers and a blanket agreement has many releases; without an explicit parent edge you cannot tell which quote won or how much of the agreement has been consumed. Deriving it from supplier and date is a guess, not a link.
# How it works: self-link between two Purchase rows, exactly like EmployeeEmployeeAppointment uses related_employee_id for the second side. `link_type` separates the two meanings so one table serves both without a second join table.
# Main associations: belongs_to :company, :purchase, :related_purchase (Purchase).
class PurchaseParentAppointment < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :link_type, PURCHASE_LINK_TYPES, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :purchase
  belongs_to :related_purchase, class_name: "Purchase"

  # --- Validations ---
  validates :purchase_id, uniqueness: { scope: [ :related_purchase_id, :link_type ] }
  validate :parent_differs_from_child

  private

  def parent_differs_from_child
    return if purchase_id.blank? || purchase_id != related_purchase_id

    errors.add(:related_purchase, "cannot be the same document")
  end
end
