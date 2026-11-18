# frozen_string_literal: true

# QualityInspection — Atomic purpose: one inspection event at a checkpoint (receiving, in-process, final) against a specific subject.
#
# Why it exists: quality is a checkpoint, not a rating: goods must be provably inspected before they are received or dispatched, and the inspection has to name what was inspected. Without the header the individual measurements have no context.
# How it works: `subject_type`/`subject_id` is polymorphic because checkpoints attach to goods receipts, production orders and dispatches alike — the same immutable-reference precedent as the workflow log. Checks are QualityChecks; a failed inspection opens NonConformances.
# Main associations: belongs_to :company, :subject (polymorphic), :inspector_employee (optional); has_many :quality_checks, :non_conformances.
class QualityInspection < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :inspection_type, QUALITY_INSPECTION_TYPES, prefix: true, default: :receiving

  # --- Associations ---
  belongs_to :company
  belongs_to :subject, polymorphic: true
  belongs_to :inspector_employee, class_name: "Employee", optional: true
  has_many :quality_checks, dependent: :destroy
  has_many :non_conformances, dependent: :nullify

  # --- Scopes ---
  scope :failed, -> { where(status: :failed) }

  # --- Validations ---
  validates :subject_type, :subject_id, presence: true

  # --- Methods ---
  def passed?
    quality_checks.any? && quality_checks.all? { |check| check.result_pass? }
  end
end
