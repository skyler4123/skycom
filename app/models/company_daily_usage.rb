# frozen_string_literal: true

# CompanyDailyUsage — Atomic purpose: persist hourly credit usage (metadata
# keys h0..h23) for one company/day. Values are credits consumed per hour.
# Written by CompanyUsageSyncJob draining Kredis counters; read through the
# hour_usage/add_hour_usage helpers — never access metadata directly.
class CompanyDailyUsage < ApplicationRecord
  HOURS = (0..23).freeze

  store_accessor :metadata, *(0..23).map { |i| "h#{i}" }
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed

  validates :usage_date, presence: true

  def self.find_or_create_for(company, date)
    find_or_create_by!(company: company, usage_date: date)
  end

  def hour_usage(hour)
    validate_hour!(hour)
    public_send("h#{hour}").to_i
  end

  def set_hour_usage(hour, value)
    validate_hour!(hour)
    public_send("h#{hour}=", value.to_i)
    save!
  end

  def add_hour_usage(hour, delta)
    validate_hour!(hour)
    public_send("h#{hour}=", hour_usage(hour) + delta.to_i)
    save!
  end

  def total_credits
    HOURS.sum { |hour| public_send("h#{hour}").to_i }
  end

  private

  def validate_hour!(hour)
    raise ArgumentError, "hour must be within #{HOURS}" unless HOURS.cover?(hour.to_i)
  end
end
