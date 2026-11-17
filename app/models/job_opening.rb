# frozen_string_literal: true

# JobOpening — Atomic purpose: one open position a company is recruiting for.
#
# Why it exists: applicants, interviews and offers all belong to a position; without the opening there is no headcount context, no way to compare candidates for the same role, and no answer to 'which roles are open'.
# How it works: belongs to a branch (and department when the org uses them), carries the description and an open/closed window. Stage movement of applicants reuses Workflow, so this row only owns the requisition itself.
# Main associations: belongs_to :company, :branch (optional), :department (optional); has_many :applicants, :employees.
class JobOpening < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :department, optional: true
  has_many :applicants, dependent: :restrict_with_error
  has_many :employees, dependent: :nullify

  # --- Scopes ---
  scope :open_openings, -> { where(status: [ :pending, :in_progress ]) }

  # --- Validations ---
  validates :title, presence: true, length: { maximum: 255 }
  validates :openings_count, numericality: { only_integer: true, greater_than: 0 }
end
