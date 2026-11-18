# frozen_string_literal: true

# WorkCenter — Atomic purpose: one machine or assembly line that work can be scheduled on, with its capacity and hourly cost.
#
# Why it exists: finite capacity scheduling and production cost both need the resource: how many units per hour it makes (so a bottleneck is visible) and what an hour costs (so standard cost is not a guess).
# How it works: belongs to a branch; `capacity_per_hour` bounds scheduling, `cost_per_hour_cents` feeds standard costing. Machine usage is recorded in MachineReadings rather than a counter column, keeping the row about the resource.
# Main associations: belongs_to :company, :branch (optional); has_many :production_operations, :production_order_operations, :machine_readings.
class WorkCenter < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  has_many :production_operations, dependent: :restrict_with_error
  has_many :production_order_operations, dependent: :restrict_with_error
  has_many :machine_readings, dependent: :destroy

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :company_id }
  validates :capacity_per_hour, numericality: { greater_than: 0 }
  validates :cost_per_hour_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
