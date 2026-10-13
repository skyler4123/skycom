# frozen_string_literal: true

# PromoGrant — Atomic purpose: per-company audit row of one PromoCampaign grant.
# Written only by PromoCampaigns::ExecuteService alongside the wallet credit.
# Uniqueness on [promo_campaign_id, company_id] is the idempotency key.
class PromoGrant < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :promo_campaign
  belongs_to :company

  # --- Validations ---
  validates :granted_amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :promo_before, presence: true, numericality: { only_integer: true }
  validates :promo_after, presence: true, numericality: { only_integer: true }
end
