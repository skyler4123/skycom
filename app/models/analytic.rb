# frozen_string_literal: true

# Analytic — Atomic purpose: per-company analytics layout record. The first row
# is the analytics page rendered at /companies/:company_id/analytics.
#
# Why it exists: lets a company choose which analytics sections are visible
# without code changes; one row per company is enough for now, but the table is
# shaped to allow more analytics layouts later.
# How it works: metadata["blocks"] stores the active block keys in render order.
# An empty/missing value falls back to BLOCKS (all sections active). Unknown and
# duplicate keys are rejected by validation.
# Main associations: belongs_to :company (touch).
class Analytic < ApplicationRecord
  DEFAULT_NAME = "Company Analytics"

  # Every configurable analytics block, in canonical render order.
  BLOCKS = %w[
    pillars
    secondary_metrics
    margin_chart
    revenue_mix
    top_items
    cohorts
    inventory
    workforce
    clv
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
