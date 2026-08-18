# frozen_string_literal: true

# CompanyMonthlyUsage — Atomic purpose: persist daily credit usage (metadata
# keys d1..d31) for one company/month. Values are credits consumed per day.
# Written by CompanyUsageSyncJob draining the Kredis counter; read through the
# day_usage/add_day_usage helpers — never access metadata directly.
# total_credits is a denormalized sum of the slots, maintained by the helpers
# as a debug aid.
class CompanyMonthlyUsage < ApplicationRecord
  DAYS = (1..31).freeze

  store_accessor :metadata, *(1..31).map { |i| "d#{i}" }
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed

  validates :usage_month, presence: true

  def self.find_or_create_for(company, month)
    find_or_create_by!(company: company, usage_month: month)
  end

  def day_usage(day)
    validate_day!(day)
    public_send("d#{day}").to_i
  end

  def set_day_usage(day, value)
    validate_day!(day)
    public_send("d#{day}=", value.to_i)
    recompute_total_credits!
  end

  def add_day_usage(day, delta)
    validate_day!(day)
    public_send("d#{day}=", day_usage(day) + delta.to_i)
    recompute_total_credits!
  end

  private

  def validate_day!(day)
    raise ArgumentError, "day must be within #{DAYS}" unless DAYS.cover?(day.to_i)
  end

  def recompute_total_credits!
    self.total_credits = DAYS.sum { |day| public_send("d#{day}").to_i }
    save!
  end
end
