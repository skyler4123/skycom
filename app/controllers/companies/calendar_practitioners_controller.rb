# app/controllers/companies/calendar_practitioners_controller.rb
#
# The bookable staff roster — JSON API (Shell-First). A practitioner is a
# bridge: it points at a real Employee (or User) through the polymorphic
# source_type / source_id pair, so this controller only ever writes the bridge,
# never the ERP record.
#
# index supports ?q= and ?calendar_position_id= / ?branch_id= / ?bookable=
# filters via plain SQL — the calendar module is deliberately isolated from the
# dynamic-property + Meilisearch stack (docs/CALENDAR.md §2).
#
# Serves Stimulus: Companies_CalendarPractitioners_IndexController (index JSON incl. q passthrough),
#                  Companies_CalendarPractitioners_NewController|EditController
# Depends on BE: GET /companies/:company_id/calendar_practitioners.json
# Endpoints: GET    /companies/:company_id/calendar_practitioners(.json)
#            GET    /companies/:company_id/calendar_practitioners/:id(.json)
#            GET    /companies/:company_id/calendar_practitioners/new(.json)
#            GET    /companies/:company_id/calendar_practitioners/:id/edit(.json)
#            POST   /companies/:company_id/calendar_practitioners(.json)
#            PATCH  /companies/:company_id/calendar_practitioners/:id(.json)
#            DELETE /companies/:company_id/calendar_practitioners/:id(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarPractitionersController < Companies::ApplicationController
  include Companies::CalendarSerializable

  TABLE = "calendar_practitioners".freeze

  before_action :set_calendar_practitioner, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = filtered_scope
        @pagy, records = pagy(:offset, scope, jsonapi: true)

        render json: {
          calendar_practitioners: records.map { |record| format_practitioner(record) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_practitioner: format_practitioner(calendar_practitioner) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          calendar_practitioner: { bookable: true, source_type: "Employee" },
          options: practitioner_options
        }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          calendar_practitioner: format_practitioner(calendar_practitioner),
          options: practitioner_options
        }
      end
    end
  end

  def create
    practitioner = current_company.calendar_practitioners.new(practitioner_params)

    if practitioner.save
      render json: {
        calendar_practitioner: format_practitioner(practitioner),
        message: "Practitioner created successfully!"
      }
    else
      render json: { errors: practitioner.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if calendar_practitioner.update(practitioner_params)
      render json: {
        calendar_practitioner: format_practitioner(calendar_practitioner),
        message: "Practitioner updated successfully!"
      }
    else
      render json: { errors: calendar_practitioner.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    calendar_practitioner.destroy!

    render json: { message: "Practitioner deleted successfully!" }
  end

  private

  def calendar_practitioner
    @calendar_practitioner ||= current_company.calendar_practitioners.find(params[:id])
  end

  def set_calendar_practitioner
    calendar_practitioner
  end

  def format_practitioner(practitioner)
    practitioner.as_json(only: [
      :id, :name, :color, :bookable, :calendar_position_id, :branch_id,
      :source_type, :source_id, :lifecycle_status, :created_at, :updated_at
    ]).merge(
      display_color: practitioner.display_color,
      linked: practitioner.linked?,
      source_display_name: practitioner.source_display_name,
      calendar_position: practitioner.calendar_position&.as_json(only: [ :id, :name, :color ])
    )
  end

  # Both pickers for the form. Employees are served from the BE (id + name only)
  # because there is no employees accessor on the client cache.
  def practitioner_options
    { positions: current_company.calendar_positions.bookable.ordered.map { |p|
        { id: p.id, name: p.name, color: p.color, default_duration_minutes: p.default_duration_minutes }
      },
      employees: current_company.employees.order(:name).map { |e|
        { id: e.id, name: e.name }
      } }
  end

  def filtered_scope
    scope = current_company.calendar_practitioners.ordered.includes(:calendar_position)
    scope = scope.where(calendar_position_id: params[:calendar_position_id]) if params[:calendar_position_id].present?
    scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
    scope = scope.where(bookable: params[:bookable] == "true") if params[:bookable].present?
    scope = scope.where(lifecycle_status: params[:lifecycle_status]) if params[:lifecycle_status].present?

    term = params[:q].to_s.strip
    return scope if term.blank?

    scope.where("#{TABLE}.name ILIKE :q", q: "%#{ActiveRecord::Base.sanitize_sql_like(term)}%")
  end

  def practitioner_params
    params.require(:calendar_practitioner).permit(
      :name, :color, :bookable, :calendar_position_id, :branch_id,
      :source_type, :source_id, :lifecycle_status
    )
  end
end
