# app/controllers/companies/calendars_controller.rb
#
# Calendar/Schedule board — the month / week / day grid. Shell-First: #index
# renders an empty layout and the Stimulus controller draws everything.
#
# #events is the grid's range query. It returns the same field names the
# reusable `calendar` Stimulus controller already understands
# (id / title / start / end / allDay / backgroundColor / extendedProps), so the
# board and the /demo mock are the same widget pointed at different endpoints.
# Cancelled events are excluded (CalendarEvent.board_visible) — a cancelled
# booking should not occupy a slot, but a completed or no-show one still did.
#
# Serves Stimulus: Companies_Calendars_IndexController (index shell + events JSON range)
# Depends on BE: GET /companies/:company_id/calendars(.json)
# Endpoints: GET /companies/:company_id/calendars(.json)            — board shell
#            GET /companies/:company_id/calendars/events.json?start=&end= — range query
# Docs: docs/CALENDAR.md
class Companies::CalendarsController < Companies::ApplicationController
  include Companies::CalendarSerializable

  DEFAULT_RANGE_MONTHS = 3

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          calendar: {
            today: Time.current.iso8601,
            timezone: Time.zone.name,
            events: current_company.calendar_events.board_visible.count
          }
        }
      end
    end
  end

  # The grid asks for exactly the window it is displaying.
  def events
    range = requested_range

    events = current_company.calendar_events
      .board_visible
      .overlapping(range.first, range.last)
      .includes(:calendar_procedure, { calendar_event_practitioners: :calendar_practitioner },
                { calendar_event_locations: :calendar_location },
                { calendar_event_equipment: :calendar_equipment },
                { calendar_event_participants: :calendar_participant })
      .ordered
      .limit(MAX_RANGE_EVENTS)

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { events: events.map(&:to_calendar_payload) } }
    end
  end

  private

  # Cap the window so a client cannot ask for a decade of bookings in one query.
  MAX_RANGE_EVENTS = 2_000

  # Falls back to a window around today when start/end are missing or inverted.
  # Both ends are widened to cover their whole day: the grid asks with plain
  # YYYY-MM-DD, and an end of midnight would drop everything after 00:00 on the
  # final day (the overlap probe is half-open).
  def requested_range
    starts_at = (parse_date(params[:start]) || Time.current).beginning_of_day
    ends_at = (parse_date(params[:end]) || (starts_at + DEFAULT_RANGE_MONTHS.months)).end_of_day
    ends_at = (starts_at + DEFAULT_RANGE_MONTHS.months).end_of_day if ends_at <= starts_at
    [ starts_at, ends_at ]
  end

  def parse_date(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
