# frozen_string_literal: true

# ProjectBillingTerm — Atomic purpose: how one project is billed: fixed price, milestone, time & materials, or retainer.
#
# Why it exists: the same project can be sold four ways and each needs different data — a cap, a rate, a retainer period. Keeping the model on the project row would force every project to pretend it is time & materials, and revenue recognition would be wrong for the other three.
# How it works: one row per project. `cap_cents` makes fixed-price and not-to-exceed contracts enforceable, `rate_cents` prices T&M, `retainer_period_days` sets the retainer cycle. Actual billing goes through orders/invoices, never through this row.
# Main associations: belongs_to :company, :project.
class ProjectBillingTerm < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :billing_model, PROJECT_BILLING_MODELS, prefix: true, default: :time_and_materials

  # --- Associations ---
  belongs_to :company
  belongs_to :project

  # --- Validations ---
  validates :project_id, uniqueness: { scope: :company_id }
  validates :rate_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # --- Methods ---
  def capped?
    cap_cents.present?
  end

  def cap_reached?(billed_cents)
    capped? && billed_cents.to_i >= cap_cents.to_i
  end
end
