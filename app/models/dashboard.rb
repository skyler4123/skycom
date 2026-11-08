# frozen_string_literal: true

# Dashboard — Atomic purpose: per-company dashboard layout record. The first row
# is the dashboard rendered at /companies/:company_id/dashboards.
#
# Why it exists: lets a company choose which dashboard sections are visible
# without code changes; one row per company is enough for now, but the table is
# shaped to allow more dashboards later.
# How it works: metadata["blocks"] stores the active block keys in render order.
# An empty/missing value falls back to BLOCKS (all sections active). Unknown and
# duplicate keys are rejected by validation.
# Main associations: belongs_to :company (touch).
class Dashboard < ApplicationRecord
  DEFAULT_NAME = "Company Dashboard"

  # Every configurable dashboard block, in canonical render order.
  BLOCKS = %w[
    company_meta
    kpis
    revenue_orders
    sales_channels
    attention
    recent_orders
    top_customers
    staff_today
    upcoming_events
    company_wallet
  ].freeze

  attribute :permission_resource_name, :string, default: -> { self.name }
  store_accessor :metadata, :blocks

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, { inactive: 0, active: 1 }, prefix: true, default: :active

  # --- Associations ---
  belongs_to :company, touch: true

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :workflow_status, presence: true
  validate :blocks_shape

  def blocks
    stored = super
    stored.nil? ? self.class::BLOCKS : stored
  end

  def blocks=(value)
    super(value.is_a?(Array) ? value.map(&:to_s) : value)
  end

  def active_blocks
    return [] unless blocks.is_a?(Array)

    self.class::BLOCKS & blocks
  end

  private

  def blocks_shape
    value = blocks
    unless value.is_a?(Array)
      errors.add(:blocks, "must be an array")
      return
    end

    unknown = value - self.class::BLOCKS
    errors.add(:blocks, "contains unknown blocks: #{unknown.join(', ')}") if unknown.any?
    errors.add(:blocks, "contains duplicate blocks") if value.uniq.length != value.length
  end
end
