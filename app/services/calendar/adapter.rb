# app/services/calendar/adapter.rb
#
# Abstract seam for an external scheduling provider (Cal.com, Google,
# Outlook). Skycom owns its data; the provider owns nothing in the ERP. This
# class is the ONLY place that would ever speak a provider's wire format.
#
# No subclass exists yet. The intent is that adding Cal.com later means adding
# one file — `Calendar::CalcomAdapter` — plus a line in Calendar::AdapterFactory.
# Nothing in the models, controllers or jobs needs to move.
#
# Implementations must:
#   * write `external_id` / `external_etag` via #mark_synced! on success
#   * write a CalendarSyncLog row per attempt, success or failure
#   * never mutate Skycom business rules — the provider's answer is raw data
#   * never reach outside `company` (tenancy is the caller's contract)
#
# @see docs/CALENDAR.md §7
class Calendar::Adapter
  # Rescuable on purpose: Ruby's built-in NotImplementedError descends from
  # ScriptError, so `rescue => e` would not catch it.
  class NotImplementedError < StandardError; end

  attr_reader :company

  def initialize(company)
    @company = company
  end

  # Provider key this adapter handles. Must match a CALENDAR_SYNC_PROVIDERS entry.
  def provider
    raise NotImplementedError, "#{self.class.name} must declare its #provider"
  end

  # Pushes a local resource (practitioner / location / equipment / procedure) to
  # the provider and records the returned external id.
  def sync_resource(record)
    raise NotImplementedError, "#{self.class.name}#sync_resource"
  end

  # Creates the booking at the provider. Returns the external id.
  def create_event(calendar_event)
    raise NotImplementedError, "#{self.class.name}#create_event"
  end

  # Pushes a local change (time, status, assignments) to the provider.
  def update_event(calendar_event)
    raise NotImplementedError, "#{self.class.name}#update_event"
  end

  # Cancels the booking at the provider. The local row is NOT touched here.
  def cancel_event(calendar_event)
    raise NotImplementedError, "#{self.class.name}#cancel_event"
  end

  # Fetches the provider's bookings in a window, as raw CalendarEvent-shaped
  # hashes. The caller decides how to reconcile them.
  #
  # @return [Array<Hash>] each with :id, :title, :start, :end, :all_day
  def fetch_events(from:, to:)
    raise NotImplementedError, "#{self.class.name}#fetch_events"
  end

  # Asks the provider which slots are free for a procedure between two instants,
  # optionally constrained to specific resources.
  #
  # Skycom does NOT compute free slots from CalendarAvailabilityRule today — a
  # provider that owns scheduling logic is authoritative, and that is exactly
  # why the availability rules are stored raw.
  #
  # @return [Array<Hash>] each with :starts_at, :ends_at
  def available_slots(calendar_procedure:, from:, to:, practitioners: [], locations: [], equipment: [])
    raise NotImplementedError, "#{self.class.name}#available_slots"
  end

  private

  # Appends one row to the audit trail. Every adapter call funnels through here
  # so the Sync page has a complete history.
  def log_sync(direction:, entity:, status:, request: {}, response: {}, error: nil, external_id: nil, duration_ms: nil)
    CalendarSyncLog.create!(
      company: company,
      calendar_sync_connection: connection,
      provider: provider,
      direction: direction,
      entity_type: entity.class.name,
      entity_id: entity.id,
      external_id: external_id || entity.try(:external_id),
      status: status,
      request_payload: request,
      response_payload: response,
      error_message: error&.to_s&.truncate(5_000),
      duration_ms: duration_ms
    )
  end

  def connection
    @connection ||= company.calendar_sync_connections.for_provider(provider).first
  end
end
