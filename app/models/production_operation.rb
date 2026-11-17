# frozen_string_literal: true

# ProductionOperation — Atomic purpose: one step in a routing: which work center runs it, in what order, with setup and run time per unit.
#
# Why it exists: capacity scheduling needs minutes per unit and setup time per batch, otherwise the plan has no duration and the machine is either idle or overloaded. Separating setup from run time is what makes small batches honestly expensive.
# How it works: ordered child of a routing with a work center. Times are integers (minutes) so scheduling arithmetic stays exact. Actual work is recorded on ProductionOrderOperations, never by editing the template.
# Main associations: belongs_to :company, :production_routing, :work_center (optional).
class ProductionOperation < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :production_routing
  belongs_to :work_center, optional: true
  has_many :production_order_operations, dependent: :restrict_with_error

  # --- Scopes ---
  scope :ordered, -> { order(:position) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :production_routing_id }
  validates :setup_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # --- Methods ---
  def planned_minutes_for(quantity)
    setup_minutes.to_i + (run_minutes_per_unit.to_d * quantity.to_d)
  end
end
