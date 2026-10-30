# frozen_string_literal: true

# PromoGrant — Atomic purpose: per-company audit row of one PromoCampaign grant.
#
# Why it exists: the grant must be idempotent and auditable per company, recording
# the promo balance before/after and the amount granted.
# How it works: written only by PromoCampaigns::ExecuteService alongside the wallet
# credit; uniqueness on [promo_campaign_id, company_id] is the idempotency key.
# Main associations: belongs_to :promo_campaign, :company (required).
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
