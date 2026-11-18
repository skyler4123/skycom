# frozen_string_literal: true

# ProjectMilestone — Atomic purpose: a billable checkpoint of a project with its amount, due date and invoice link.
#
# Why it exists: milestone billing needs a named deliverable that can be invoiced independently; without a row per milestone the invoice line has no reference and a client cannot see what they are paying for.
# How it works: one row per milestone with an amount and due date; `invoice_id` records the invoice that billed it so a milestone cannot be invoiced twice. Status tracks pending → invoiced → paid without a separate state machine.
# Main associations: belongs_to :company, :project, :invoice (optional).
class ProjectMilestone < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :project
  belongs_to :invoice, optional: true

  # --- Scopes ---
  scope :due_before, ->(date) { where(due_on: ..date) }
  scope :invoiced, -> { where.not(invoice_id: nil) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
