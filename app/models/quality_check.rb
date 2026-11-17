# frozen_string_literal: true

# QualityCheck — Atomic purpose: one measured characteristic inside an inspection, with its acceptable range and result.
#
# Why it exists: an inspection that only records pass/fail cannot explain a defect or support a supplier claim; storing the characteristic, its bounds and the measured value is what makes a rejection defensible.
# How it works: child rows of an inspection. Bounds and measured values are decimals at measurement precision, not money. Result is an enum so a conditional acceptance is distinguishable from a pass.
# Main associations: belongs_to :company, :quality_inspection.
class QualityCheck < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :result, QUALITY_RESULTS, prefix: true, default: :pass

  # --- Associations ---
  belongs_to :company
  belongs_to :quality_inspection

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  # --- Methods ---
  def within_bounds?
    return true if measured_value.nil?

    (min_value.nil? || measured_value >= min_value) && (max_value.nil? || measured_value <= max_value)
  end
end
