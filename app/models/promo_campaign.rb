# frozen_string_literal: true

# PromoCampaign — Atomic purpose: one-shot admin promo-credit giveaway config.
# System-level (no company_id): Admin matches companies via `conditions`,
# grants `amount` promo credits each capped at `max_cap`, runs once at
# `scheduled_at` through PromoCampaignJob. Per-company results live on PromoGrant.
class PromoCampaign < ApplicationRecord
  CONDITION_KEYS = %w[
    country business_type
    employee_count_min employee_count_max
    created_after created_before
    promo_balance_min promo_balance_max
    company_ids
  ].freeze

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, { draft: 0, scheduled: 1, processing: 2, completed: 3, failed: 4 }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  has_many :promo_grants, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true
  validates :title, presence: true
  validates :body, presence: true
  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :max_cap, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :scheduled_at, presence: true
  validate :conditions_shape

  private

  def conditions_shape
    conds = conditions || {}
    unless conds.is_a?(Hash)
      errors.add(:conditions, "must be an object")
      return
    end

    unknown = conds.keys.map(&:to_s) - CONDITION_KEYS
    errors.add(:conditions, "unknown keys: #{unknown.join(', ')}") if unknown.any?

    if conds["country"].present?
      valid = COUNTRY_CODES.keys.map(&:to_s)
      bad = Array(conds["country"]).map(&:to_s) - valid
      errors.add(:conditions, "unknown country: #{bad.join(', ')}") if bad.any?
    end

    if conds["business_type"].present?
      valid = Company.business_types.keys - [ "system" ]
      bad = Array(conds["business_type"]).map(&:to_s) - valid
      errors.add(:conditions, "unknown business_type: #{bad.join(', ')}") if bad.any?
    end

    if conds["employee_count_min"].present? && conds["employee_count_max"].present? &&
        conds["employee_count_min"].to_i > conds["employee_count_max"].to_i
      errors.add(:conditions, "employee_count_min must be <= employee_count_max")
    end

    if conds["promo_balance_min"].present? && conds["promo_balance_max"].present? &&
        conds["promo_balance_min"].to_i > conds["promo_balance_max"].to_i
      errors.add(:conditions, "promo_balance_min must be <= promo_balance_max")
    end

    %w[created_after created_before].each do |key|
      next if conds[key].blank?

      begin
        Time.zone.parse(conds[key].to_s) || raise(ArgumentError)
      rescue ArgumentError
        errors.add(:conditions, "#{key} must be a valid date")
      end
    end

    if conds["company_ids"].present?
      ids = Array(conds["company_ids"]).map(&:to_s).reject(&:blank?)
      bad = ids.reject { |v| v.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i) }
      errors.add(:conditions, "company_ids must be valid UUIDs") if bad.any?
    end
  end
end
