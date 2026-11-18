# frozen_string_literal: true

# ProjectTimeEntry — Atomic purpose: hours one employee worked on one task on one day, with billability and the rate snapshotted.
#
# Why it exists: billable work has to become an invoice line and an internal cost at the same time; a timesheet row is the only place both the rate charged to the client and the hours paid to the employee can be frozen together, so later rate changes never rewrite an issued invoice.
# How it works: minutes rather than hours so half-hours stay exact. `rate_cents` is snapshotted at approval. `invoice_id` is set when the entry is billed, which is what makes re-billing impossible. Status supports draft → submitted → approved → billed.
# Main associations: belongs_to :company, :project, :task (optional), :employee, :invoice (optional).
class ProjectTimeEntry < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :project
  belongs_to :task, optional: true
  belongs_to :employee
  belongs_to :invoice, optional: true

  # --- Scopes ---
  scope :billable, -> { where(billable: true) }
  scope :unbilled, -> { where(billable: true, invoice_id: nil) }
  scope :for_period, ->(from, to) { where(worked_on: from..to) }

  # --- Validations ---
  validates :worked_on, presence: true
  validates :minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :rate_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # --- Methods ---
  def amount_cents
    (minutes.to_i * rate_cents.to_i / 60.0).round
  end
end
