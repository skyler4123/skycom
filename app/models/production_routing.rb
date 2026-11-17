# frozen_string_literal: true

# ProductionRouting — Atomic purpose: the ordered sequence of operations used to build one bill of materials.
#
# Why it exists: a recipe says what goes in, a routing says how it is made: which machine, in what order, for how long. Scheduling and labour cost both need the operations, and the sequence is what makes a bottleneck identifiable.
# How it works: belongs to a BOM and owns ordered ProductionOperations. Versioned like the BOM so a change in method does not silently rewrite the cost of past orders.
# Main associations: belongs_to :company, :bill_of_material; has_many :production_operations.
class ProductionRouting < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  belongs_to :bill_of_material
  has_many :production_operations, dependent: :destroy

  # --- Validations ---
  validates :version, presence: true, length: { maximum: 32 }
  validates :version, uniqueness: { scope: [ :company_id, :bill_of_material_id ] }
end
