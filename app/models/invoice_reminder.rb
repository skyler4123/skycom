# frozen_string_literal: true

# InvoiceReminder — Atomic purpose: one scheduled or sent dunning step for an overdue invoice.
#
# Why it exists: collections is a sequence, not a flag: level 1, 2 and 3 reminders go out on different days through different channels, and 'was this customer already chased twice' must be answerable without reading a job log. Recording each step also makes late-fee and escalation logic auditable.
# How it works: one row per (invoice, level) attempt. `scheduled_on` drives the job; `sent_at` is the evidence; `status` tracks scheduled/sent/failed/skipped. A failed send stays visible instead of being silently dropped, and re-sending after a failure creates a new attempt row rather than erasing the failure.
# Main associations: belongs_to :company, :invoice.
class InvoiceReminder < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :channel, DUNNING_CHANNELS, prefix: true, default: :email
  enum :status, INVOICE_REMINDER_STATUSES, prefix: true, default: :scheduled

  # --- Associations ---
  belongs_to :company
  belongs_to :invoice

  # --- Scopes ---
  scope :due, ->(date = Date.current) { scheduled.where(scheduled_on: ..date) }
  scope :scheduled, -> { where(status: :scheduled) }
  scope :ordered, -> { order(:level, :scheduled_on) }

  # --- Validations ---
  validates :level, numericality: { only_integer: true, greater_than: 0 }
end
