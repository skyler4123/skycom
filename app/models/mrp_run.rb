# frozen_string_literal: true

# MrpRun — Atomic purpose: one material requirements planning run: its parameters, horizon and outcome.
#
# Why it exists: MRP output is only trustworthy if it can be reproduced: which demand, which horizon, which lead times produced these suggestions. Without the run record, two planners comparing screens cannot tell why they disagree.
# How it works: stores the parameters as jsonb and a status, so a long run is visible while it executes. Suggestions are produced from demand and stock at run time; this row is the envelope that makes the result repeatable and auditable.
# Main associations: belongs_to :company.
class MrpRun < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company

  # --- Scopes ---
  scope :recent_first, -> { order(run_on: :desc, created_at: :desc) }

  # --- Validations ---
  validates :run_on, presence: true
  validates :horizon_days, numericality: { only_integer: true, greater_than: 0 }
end
