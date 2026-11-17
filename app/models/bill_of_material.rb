# frozen_string_literal: true

# BillOfMaterial — Atomic purpose: the recipe header: how many units of one finished product a set of components produces, at one version.
#
# Why it exists: production cannot be costed or exploded into material demand without a stated recipe. Versioning matters because a recipe changes while old orders must still be reproducible at the version they were built to.
# How it works: belongs to the produced product, carries the output quantity (recipes often yield 10 or 100) and a version. Components live in BomLines. A production order snapshots the BOM it used, so editing the recipe never changes an open order.
# Main associations: belongs_to :company, :product; has_many :bom_lines, :production_routings, :production_orders.
class BillOfMaterial < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  belongs_to :product
  has_many :bom_lines, dependent: :destroy
  has_many :production_routings, dependent: :destroy
  has_many :production_orders, dependent: :restrict_with_error

  # --- Scopes ---
  scope :active, -> { where(status: :confirmed) }

  # --- Validations ---
  validates :version, presence: true, length: { maximum: 32 }
  validates :output_quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :version, uniqueness: { scope: [ :company_id, :product_id ] }
end
