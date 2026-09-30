# app/models/calendar_sync_connection.rb
#
# Per-company configuration for one external scheduling provider. Nothing is
# connected in v1 — this table exists so the seam is in place and auditable
# before the first Calendar::Adapter ships.
#
# @see docs/CALENDAR.md §7
class CalendarSyncConnection < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  encrypts :credentials

  enum :status, {
    disconnected: 0,
    connected: 1,
    error: 2,
    disabled: 3
  }, prefix: true, default: :disconnected

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  has_many :calendar_sync_logs, dependent: :destroy

  # --- Scopes ---
  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :active, -> { where(status: :connected) }

  # --- Validations ---
  validates :provider, presence: true, inclusion: { in: CALENDAR_SYNC_PROVIDERS },
    uniqueness: { scope: :company_id }

  def connected?
    status_connected?
  end

  # Never serialised to the client — `credentials` holds the provider API key.
  def public_attributes
    as_json(only: [
      :id, :provider, :status, :external_organization_id, :base_url,
      :last_synced_at, :last_sync_error, :created_at, :updated_at
    ]).merge(connected: connected?)
  end
end
