# frozen_string_literal: true

# Cal.com implementation of the CalendarAdapters contract.
# Rails (host, bin/dev) talks to the isolated Cal.com Docker service at
# CALCOM_API_URL (default http://localhost:3001/api/v2). See docs/CALENDAR.md.
module CalendarAdapters
  class CalComAdapter < BaseAdapter
    def create_event(calendar_event)
      response = connection.post("bookings") do |req|
        req.body = {
          start: calendar_event.starts_at.iso8601,
          eventTypeId: integration.calcom_event_type_id,
          attendees: calendar_event.attendees,
          metadata: { skycom_event_id: calendar_event.id }
        }
      end

      return false unless response.success?

      data = response.body["data"]
      CalendarSyncMapping.create!(
        company: calendar_event.company,
        calendar_event: calendar_event,
        calendar_integration: integration,
        external_event_id: data["id"].to_s,
        external_booking_uid: data["uid"],
        last_synced_at: Time.current
      )
    end

    def process_webhook(payload)
      event_type = payload["triggerEvent"]
      booking_data = payload["payload"] || {}

      case event_type
      when "BOOKING_CREATED"
        handle_booking_created(booking_data)
      when "BOOKING_CANCELLED"
        handle_booking_cancelled(booking_data)
      when "BOOKING_RESCHEDULED"
        handle_booking_rescheduled(booking_data)
      end
    end

    private

    def handle_booking_created(data)
      mapping = CalendarSyncMapping.find_by(external_event_id: data["id"].to_s)
      return mapping if mapping.present?

      event = CalendarEvent.create!(
        company: integration.company,
        calendar_integration: integration,
        title: data["title"] || "Meeting via Cal.com",
        description: data["description"],
        starts_at: Time.parse(data["startTime"]),
        ends_at: Time.parse(data["endTime"]),
        status: :confirmed,
        meeting_url: data.dig("location", "videoCallUrl"),
        attendees: data["attendees"] || []
      )

      CalendarSyncMapping.create!(
        company: integration.company,
        calendar_event: event,
        calendar_integration: integration,
        external_event_id: data["id"].to_s,
        external_booking_uid: data["uid"],
        last_synced_at: Time.current
      )
    end

    def handle_booking_cancelled(data)
      mapping = CalendarSyncMapping.find_by(external_event_id: data["id"].to_s)
      mapping&.calendar_event&.cancelled!
    end

    def handle_booking_rescheduled(data)
      mapping = CalendarSyncMapping.find_by(external_event_id: data["id"].to_s)
      return unless mapping

      mapping.calendar_event.update!(
        starts_at: Time.parse(data["startTime"]),
        ends_at: Time.parse(data["endTime"]),
        status: :rescheduled
      )
      mapping.touch(:last_synced_at)
    end

    def connection
      @connection ||= Faraday.new(url: CALCOM_API_URL) do |f|
        f.request :json
        f.response :json
        f.headers["Authorization"] = "Bearer #{integration.access_token}"
      end
    end
  end
end
