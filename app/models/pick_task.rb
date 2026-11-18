# frozen_string_literal: true

# PickTask — Atomic purpose: one unit of work on the warehouse floor: pick this quantity of this stock from this location for this order.
#
# Why it exists: the task is what an operator sees on a handheld; it carries the assignment, the location to walk to and what was actually picked, which is what makes partial picks and substitutions possible without corrupting the order.
# How it works: generated from a released wave; `picked_quantity` differs from `quantity` on a short pick. Stock and lot are the exact rows to take, so a serialised item can be traced. Completion is recorded here and the stock movement is written through the existing ledger, never directly.
# Main associations: belongs_to :company, :pick_wave, :order, :stock, :stock_lot (optional), :storage_location (optional), :assigned_employee (optional).
class PickTask < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :pick_wave
  belongs_to :order
  belongs_to :stock
  belongs_to :stock_lot, optional: true
  belongs_to :storage_location, optional: true
  belongs_to :assigned_employee, class_name: "Employee", optional: true

  # --- Scopes ---
  scope :open_tasks, -> { where(status: [ :pending, :in_progress ]) }

  # --- Validations ---
  validates :quantity, :picked_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # --- Methods ---
  def short_picked?
    picked_quantity.to_i < quantity.to_i
  end
end
