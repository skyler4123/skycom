# app/controllers/concerns/companies/calendar_serializable.rb
#
# JSON shapes for the calendar_* module. Centralised so the board, the booking
# list and the booking form can never drift apart on field names.
#
# Every payload is assembled from `current_company` scoped relations — the
# calendar module has no default_scope (this app enforces tenancy in the
# controller layer), so scoping happens here.
#
# @see docs/CALENDAR.md
module Companies::CalendarSerializable
  extend ActiveSupport::Concern

  included do
    # A missing params key (e.g. `params.require(:calendar_event)` on an empty
    # body) otherwise renders Rails' default 400 HTML page. The calendar module
    # speaks JSON everywhere, so translate it into the documented error shape
    # (docs/API_ERROR_FORMAT.md) instead.
    rescue_from ActionController::ParameterMissing, with: :render_missing_calendar_parameter
  end

  private

  def render_missing_calendar_parameter(exception)
    render json: { errors: [ "Missing required parameter: #{exception.param}" ] },
      status: :unprocessable_content
  end

  def format_calendar_event(event)
    event.as_json(only: [
      :id, :title, :description, :notes, :location_note,
      :starts_at, :ends_at, :timezone, :all_day, :status,
      :confirmed_at, :cancelled_at, :cancellation_reason,
      :calendar_procedure_id, :branch_id, :lifecycle_status,
      :created_at, :updated_at
    ]).merge(
      display_title: event.display_title,
      color: event.display_color,
      duration_minutes: event.duration_minutes,
      blocking: event.blocking?,
      calendar_procedure: event.calendar_procedure&.as_json(only: [ :id, :name, :color, :duration_minutes, :slug ]),
      practitioners: format_assignments(event.calendar_event_practitioners, :calendar_practitioner),
      locations: format_assignments(event.calendar_event_locations, :calendar_location),
      equipment: format_assignments(event.calendar_event_equipment, :calendar_equipment),
      participants: format_assignments(event.calendar_event_participants, :calendar_participant)
    )
  end

  # One shape for all four join tables so the FE has a single renderer.
  # `owner` is the belongs_to on the join model pointing at the resource.
  def format_assignments(assignments, owner)
    assignments.map do |assignment|
      {
        id: assignment.public_send(:"#{owner}_id"),
        name: assignment.public_send(owner)&.name,
        role: assignment.role,
        required: assignment.required
      }
    end
  end

  def format_calendar_procedure(procedure)
    procedure.as_json(only: [
      :id, :name, :code, :slug, :description, :duration_minutes,
      :buffer_before_minutes, :buffer_after_minutes, :min_lead_minutes, :color,
      :requires_location, :requires_equipment, :requires_practitioners,
      :calendar_position_id, :branch_id, :source_type, :source_id,
      :lifecycle_status, :created_at, :updated_at
    ]).merge(
      blocked_minutes: procedure.blocked_minutes,
      source_display_name: procedure.source_display_name,
      calendar_position: procedure.calendar_position&.as_json(only: [ :id, :name, :color ])
    )
  end

  # Shared by positions / practitioners / locations / equipment / participants.
  # `extra` carries the fields unique to one resource type.
  def format_calendar_resource(record, extra = {})
    base = {
      id: record.id,
      name: record.name,
      code: record.try(:code),
      description: record.try(:description),
      color: record.try(:display_color) || record.try(:color),
      lifecycle_status: record.lifecycle_status,
      created_at: record.created_at,
      updated_at: record.updated_at
    }
    base.merge(extra)
  end

  # Options for the pickers on the booking form. Deliberately compact — the
  # new/edit controllers fetch the same shapes so a picker and the record it
  # selects never disagree.
  def calendar_picker_options
    company = current_company
    {
      procedures: company.calendar_procedures.active.ordered.includes(:calendar_position).map { |p|
        { id: p.id, name: p.name, color: p.color, duration_minutes: p.duration_minutes,
          requires_location: p.requires_location, requires_equipment: p.requires_equipment,
          requires_practitioners: p.requires_practitioners, calendar_position_id: p.calendar_position_id }
      },
      practitioners: company.calendar_practitioners.bookable.ordered.includes(:calendar_position).map { |p|
        { id: p.id, name: p.name, color: p.display_color, calendar_position_id: p.calendar_position_id,
          branch_id: p.branch_id, bookable: p.bookable }
      },
      locations: company.calendar_locations.bookable.ordered.map { |l|
        { id: l.id, name: l.name, color: l.color, capacity: l.capacity, branch_id: l.branch_id }
      },
      equipment: company.calendar_equipments.bookable.ordered.map { |e|
        { id: e.id, name: e.name, color: e.color, quantity: e.quantity, branch_id: e.branch_id }
      },
      participants: company.calendar_participants.ordered.map { |p|
        { id: p.id, name: p.name, email: p.email, phone_number: p.phone_number }
      }
    }
  end
end
