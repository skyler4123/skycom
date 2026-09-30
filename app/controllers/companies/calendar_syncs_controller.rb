# app/controllers/companies/calendar_syncs_controller.rb
#
# Read-only view of the external scheduling provider seam: one row per
# CALENDAR_SYNC_PROVIDERS entry (whether or not it is connected) plus the
# recent calendar_sync_logs audit trail.
#
# Nothing here connects anything. The provider set is declared in
# config/initializers/constants.rb; Calendar::AdapterFactory.REGISTRY is empty,
# so every entry reports connected: false. That is the honest state of v1 —
# Skycom runs its own scheduling (docs/CALENDAR.md §7).
#
# `credentials` is never serialised: CalendarSyncConnection#public_attributes
# whitelists the safe keys and the column is Active Record encrypted at rest.
#
# Serves Stimulus: Companies_CalendarSyncs_IndexController (connections + recent logs)
# Depends on BE: GET /companies/:company_id/calendar_syncs.json
# Endpoints: GET /companies/:company_id/calendar_syncs(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarSyncsController < Companies::ApplicationController
  RECENT_LOG_LIMIT = 50

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          calendar_syncs: {
            providers: providers_payload,
            recent_logs: recent_logs_payload
          }
        }
      end
    end
  end

  private

  def connections
    @connections ||= current_company.calendar_sync_connections.index_by(&:provider)
  end

  # One entry per supported provider, so the UI can show "Cal.com — not
  # connected" rather than silently omitting it.
  def providers_payload
    CALENDAR_SYNC_PROVIDERS.map do |provider|
      connection = connections[provider]
      adapter = Calendar::AdapterFactory.available?(provider)

      {
        provider: provider,
        adapter_available: adapter,
        connected: connection&.connected? || false,
        status: connection&.status || "disconnected",
        external_organization_id: connection&.external_organization_id,
        base_url: connection&.base_url,
        last_synced_at: connection&.last_synced_at,
        last_sync_error: connection&.last_sync_error
      }
    end
  end

  def recent_logs_payload
    current_company.calendar_sync_logs
      .includes(:calendar_sync_connection)
      .recent_first
      .limit(RECENT_LOG_LIMIT)
      .map do |log|
        {
          id: log.id,
          provider: log.provider,
          direction: log.direction,
          status: log.status,
          entity_type: log.entity_type,
          entity_id: log.entity_id,
          external_id: log.external_id,
          error_message: log.error_message,
          duration_label: log.duration_label,
          created_at: log.created_at
        }
      end
  end
end
