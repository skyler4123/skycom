# frozen_string_literal: true

# MaintenanceCheck — Atomic purpose: one checklist item a technician must confirm during preventive maintenance.
#
# Why it exists: a maintenance visit without a checklist is a signature, not a service: the checks are what make the record auditable and what a warranty claim depends on.
# How it works: ordered child rows of a plan with an instruction and a required flag. Results are recorded on the visit, not here, so the same plan can be reused without overwriting history.
# Main associations: belongs_to :company, :maintenance_plan.
class MaintenanceCheck < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :maintenance_plan

  # --- Scopes ---
  scope :ordered, -> { order(:position) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :maintenance_plan_id }
end
