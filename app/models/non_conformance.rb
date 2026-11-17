# frozen_string_literal: true

# NonConformance — Atomic purpose: one recorded quality defect with its severity, disposition and resolution.
#
# Why it exists: a defect that is only mentioned in a chat never gets fixed and never reaches the supplier scorecard; recording severity and disposition is what turns a complaint into a trackable corrective action and a cost.
# How it works: may reference an inspection, a production order, a goods receipt or a product — the sources differ, so the links are concrete optional columns rather than a polymorphic appointment. Status tracks open → resolved; `resolved_at` is the evidence.
# Main associations: belongs_to :company, :quality_inspection (optional), :production_order (optional), :stock_import (optional), :product (optional).
class NonConformance < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :severity, NON_CONFORMANCE_SEVERITIES, prefix: true, default: :minor
  enum :disposition, NON_CONFORMANCE_DISPOSITIONS, prefix: true, default: :rework

  # --- Associations ---
  belongs_to :company
  belongs_to :quality_inspection, optional: true
  belongs_to :production_order, optional: true
  belongs_to :stock_import, optional: true
  belongs_to :product, optional: true

  # --- Scopes ---
  scope :open_defects, -> { where(status: [ :draft, :pending, :in_progress ]) }

  # --- Validations ---
  validates :description, presence: true, length: { maximum: 5_000 }
end
