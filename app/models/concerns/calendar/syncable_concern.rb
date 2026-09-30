# app/models/concerns/calendar/syncable_concern.rb

# Marks a calendar_* model as synchronizable with an external scheduling
# provider (Cal.com, Google, Outlook). The module stores raw, provider-agnostic
# data and holds no scheduling logic — a future Calendar::Adapter reads and
# writes these columns. See docs/CALENDAR.md §7.
#
# No provider is wired up yet, so every record starts life as
# `sync_status: pending` and simply sits there until an adapter exists.
module Calendar::SyncableConcern
  extend ActiveSupport::Concern

  included do
    enum :sync_status, CALENDAR_SYNC_STATUSES, prefix: true, default: :pending

    scope :pending_sync, -> { where(sync_status: :pending) }
    scope :synced,       -> { where(sync_status: :synced) }
    scope :sync_failed,  -> { where(sync_status: :error) }

    # Records a provider has acknowledged — i.e. an external id was assigned.
    scope :externally_linked, -> { where.not(external_id: nil) }
  end

  # Marks the record as accepted by the provider. Called by a Calendar::Adapter
  # after a successful push.
  def mark_synced!(external_id: nil, etag: nil)
    update!(
      external_id: external_id,
      external_etag: etag,
      sync_status: :synced,
      last_synced_at: Time.current,
      last_sync_error: nil
    )
  end

  # Records a failed push. The error is kept on the record (and mirrored into
  # calendar_sync_logs by the adapter) so the UI can surface it.
  def mark_sync_failed!(error)
    update!(
      sync_status: :error,
      last_sync_error: error.to_s.truncate(2_000)
    )
  end

  # Flags the record as needing a push on the next adapter run. Called whenever
  # a syncable field changes so an edited record is not left stale at the
  # provider.
  def flag_for_sync!
    return if sync_status_synced?
    update_column(:sync_status, CALENDAR_SYNC_STATUSES[:pending])
  end

  def externally_linked?
    external_id.present?
  end

  def synced?
    sync_status_synced?
  end
end
