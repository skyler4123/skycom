# app/controllers/companies/calendar_events_controller.rb
#
# Bookings API (Shell-First). Writes go through Calendar::BookingService so the
# event and its four assignment sets are saved in one transaction and the
# hard-block conflict validation is enforced server-side.
#
# A clash comes back as `errors: [...]` with HTTP 422, never as a generic
# failure (docs/API_ERROR_FORMAT.md). #conflicts is the read-only pre-flight the
# booking form calls so the user sees a double-booking before submitting.
#
# Serves Stimulus: Companies_CalendarEvents_IndexController (index JSON + q/status/date filters),
#                  Companies_CalendarEvents_NewController|EditController|ShowController
# Depends on BE: GET /companies/:company_id/calendar_events.json
#                GET /companies/:company_id/calendar_events/conflicts.json
#                POST /companies/:company_id/calendar_events.json
# Endpoints: GET   /companies/:company_id/calendar_events(.json)            — list
#            GET   /companies/:company_id/calendar_events/:id(.json)        — show
#            GET   /companies/:company_id/calendar_events/new(.json)        — form shell
#            GET   /companies/:company_id/calendar_events/:id/edit(.json)   — form shell
#            POST  /companies/:company_id/calendar_events(.json)            — create
#            PATCH /companies/:company_id/calendar_events/:id(.json)        — update
#            DELETE /companies/:company_id/calendar_events/:id(.json)       — destroy
#            POST  /companies/:company_id/calendar_events/conflicts(.json)  — pre-flight
#            POST  /companies/:company_id/calendar_events/:id/confirm(.json)
#            POST  /companies/:company_id/calendar_events/:id/cancel(.json)
#            POST  /companies/:company_id/calendar_events/:id/complete(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarEventsController < Companies::ApplicationController
  include Companies::CalendarSerializable

  before_action :set_calendar_event, only: [ :show, :edit, :update, :destroy, :confirm, :cancel, :complete ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = filtered_scope
        @pagy, events = pagy(:offset, scope.includes(:calendar_procedure), jsonapi: true)

        render json: {
          calendar_events: events.map { |event| format_calendar_event(event) },
          pagination: @pagy.data_hash,
          options: calendar_picker_options
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_event: format_calendar_event(calendar_event) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          calendar_event: {
            status: CalendarEvent.statuses.keys.first,
            timezone: current_company.try(:timezone) || Time.zone.name,
            starts_at: Time.current.change(min: 0).iso8601
          },
          options: calendar_picker_options
        }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          calendar_event: format_calendar_event(calendar_event),
          options: calendar_picker_options
        }
      end
    end
  end

  def create
    event = Calendar::BookingService.create(
      company: current_company,
      attributes: event_params,
      **assignment_params
    )

    render json: { calendar_event: format_calendar_event(event), message: "Appointment booked successfully!" }
  rescue Calendar::BookingService::Error => e
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  def update
    event = Calendar::BookingService.update(
      calendar_event: calendar_event,
      attributes: event_params,
      **assignment_params
    )

    render json: { calendar_event: format_calendar_event(event), message: "Appointment updated successfully!" }
  rescue Calendar::BookingService::Error => e
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  def destroy
    calendar_event.destroy!

    render json: { message: "Appointment deleted successfully!" }
  end

  # Read-only pre-flight for the booking form.
  def conflicts
    conflicts = Calendar::BookingService.preview_conflicts(
      company: current_company,
      attributes: event_params,
      # When editing, the persisted booking must not be reported as its own clash.
      except_id: params[:id].presence,
      **assignment_params
    )

    render json: { conflicts: conflicts }
  rescue Calendar::BookingService::Error => e
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  def confirm
    calendar_event.confirm!

    render json: { calendar_event: format_calendar_event(calendar_event), message: "Appointment confirmed!" }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  def cancel
    calendar_event.cancel!(params[:reason])

    render json: { calendar_event: format_calendar_event(calendar_event), message: "Appointment cancelled!" }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  def complete
    calendar_event.complete!

    render json: { calendar_event: format_calendar_event(calendar_event), message: "Appointment completed!" }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  private

  def calendar_event
    @calendar_event ||= current_company.calendar_events.find(params[:id])
  end

  def set_calendar_event
    calendar_event
  end

  # index filters — plain SQL only, no Meilisearch: the calendar module is
  # deliberately isolated from the dynamic-property / search stack.
  def filtered_scope
    scope = current_company.calendar_events.includes(:calendar_procedure).ordered

    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(calendar_procedure_id: params[:calendar_procedure_id]) if params[:calendar_procedure_id].present?
    scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
    scope = scope.overlapping(range_filter.first, range_filter.last) if range_filter.any?
    scope = search_scope(scope)

    scope
  end

  def range_filter
    @range_filter ||= begin
      from = parse_time(params[:from])
      to = parse_time(params[:to])
      [ from, to ].compact
    end
  end

  # `?q=` matches the booking title, its procedure name, or any assigned
  # participant / practitioner / room name.
  def search_scope(scope)
    term = params[:q].to_s.strip
    return scope if term.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    joins = <<~SQL.squish
      LEFT JOIN calendar_event_participants cep ON cep.calendar_event_id = calendar_events.id
      LEFT JOIN calendar_participants cp ON cp.id = cep.calendar_participant_id
      LEFT JOIN calendar_event_practitioners cepr ON cepr.calendar_event_id = calendar_events.id
      LEFT JOIN calendar_practitioners cpr ON cpr.id = cepr.calendar_practitioner_id
      LEFT JOIN calendar_event_locations cel ON cel.calendar_event_id = calendar_events.id
      LEFT JOIN calendar_locations cl ON cl.id = cel.calendar_location_id
    SQL

    scope.joins(joins)
      .joins("INNER JOIN calendar_procedures ON calendar_procedures.id = calendar_events.calendar_procedure_id")
      .where(
        "calendar_events.title ILIKE :q OR calendar_procedures.name ILIKE :q OR cp.name ILIKE :q " \
        "OR cpr.name ILIKE :q OR cl.name ILIKE :q",
        q: pattern
      )
      .distinct
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def event_params
    permitted = params.require(:calendar_event).permit(
      :calendar_procedure_id, :branch_id, :title, :description, :notes, :location_note,
      :starts_at, :ends_at, :timezone, :all_day, :status, :source_type, :source_id
    )
    permitted[:status] = permitted[:status].to_s if permitted.key?(:status)
    permitted
  end

  # A nil list leaves the assignment set untouched (an edit that only moves the
  # time); an array replaces it wholesale.
  def assignment_params
    {
      practitioner_ids: id_list(:practitioner_ids),
      location_ids: id_list(:location_ids),
      equipment_ids: id_list(:equipment_ids),
      participant_ids: id_list(:participant_ids)
    }
  end

  def id_list(key)
    values = params[key]
    return nil if values.nil?

    Array(values).reject(&:blank?)
  end
end
