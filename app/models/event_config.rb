# frozen_string_literal: true

# EventConfig — Atomic purpose: per-company/category rule holder for the Event
# domain (config-style: no dynamic property slots, no CategoryConcern).
#
# Why it exists: different event types need different mechanics — a banquet holds
# stock and bills an order, a standup meeting needs neither. One row per company +
# category answers: hold stock? block or warn when a hold fails? create an order on
# completion? warn on double-booked facilities or hosts?
# How it works: belongs to company/category (category unique per company); the
# event flow reads these switches, and changes are audited in EventConfigLog.
# Main associations: belongs_to :company, :category (required); has_many
# :event_config_logs (dependent: :nullify).
class EventConfig < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :category

  has_many :event_config_logs, dependent: :nullify

  validates :category_id, uniqueness: { scope: :company_id }
end
