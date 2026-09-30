# app/models/calendar_sync_log.rb
#
# Append-only audit trail of every push / pull a Calendar::Adapter performs.
# Written by the adapter, read by the Sync page, never mutated by the client.
#
# @see docs/CALENDAR.md §7
class CalendarSyncLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :direction, CALENDAR_SYNC_DIRECTIONS, prefix: true
  enum :status, CALENDAR_SYNC_LOG_STATUSES, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :calendar_sync_connection, optional: true

  # --- Scopes ---
  scope :recent_first, -> { order(created_at: :desc) }
  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :failures, -> { where(status: :error) }

  # --- Validations ---
  validates :provider, presence: true
  validates :direction, :status, presence: true
  validates :duration_ms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def success?
    status_success?
  end

  # Time spent in the provider call, rendered for the Sync page.
  def duration_label
    return "—" if duration_ms.blank?

    duration_ms >= 1000 ? "#{(duration_ms / 1000.0).round(2)}s" : "#{duration_ms}ms"
  end
end
