# app/controllers/companies/calendar_procedures_controller.rb
#
# Bookable appointment types — JSON API (Shell-First). index supports ?q= and
# ?calendar_position_id= / ?branch_id= via plain SQL: the calendar module is
# deliberately isolated from the dynamic-property + Meilisearch stack, so there
# is no SearchQueryService here (docs/CALENDAR.md §2).
#
# A procedure always names the position that performs it, so new/edit both serve
# the position picker in `options`.
#
# Serves Stimulus: Companies_CalendarProcedures_IndexController (index JSON incl. q passthrough),
#                  Companies_CalendarProcedures_NewController|EditController
# Depends on BE: GET /companies/:company_id/calendar_procedures.json
# Endpoints: GET    /companies/:company_id/calendar_procedures(.json)
#            GET    /companies/:company_id/calendar_procedures/:id(.json)
#            GET    /companies/:company_id/calendar_procedures/new(.json)
#            GET    /companies/:company_id/calendar_procedures/:id/edit(.json)
#            POST   /companies/:company_id/calendar_procedures(.json)
#            PATCH  /companies/:company_id/calendar_procedures/:id(.json)
#            DELETE /companies/:company_id/calendar_procedures/:id(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarProceduresController < Companies::ApplicationController
  include Companies::CalendarSerializable

  TABLE = "calendar_procedures".freeze

  before_action :set_calendar_procedure, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = filtered_scope
        @pagy, records = pagy(:offset, scope, jsonapi: true)

        render json: {
          calendar_procedures: records.map { |record| format_calendar_procedure(record) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_procedure: format_calendar_procedure(calendar_procedure) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          calendar_procedure: { duration_minutes: 30, requires_practitioners: 1, color: CALENDAR_DEFAULT_COLOR },
          options: procedure_options
        }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          calendar_procedure: format_calendar_procedure(calendar_procedure),
          options: procedure_options
        }
      end
    end
  end

  def create
    new_record = current_company.calendar_procedures.new(record_params)

    if new_record.save
      render json: {
        calendar_procedure: format_calendar_procedure(new_record),
        message: "Procedure created successfully!"
      }
    else
      render json: { errors: new_record.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if calendar_procedure.update(record_params)
      render json: {
        calendar_procedure: format_calendar_procedure(calendar_procedure),
        message: "Procedure updated successfully!"
      }
    else
      render json: { errors: calendar_procedure.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    calendar_procedure.destroy!

    render json: { message: "Procedure deleted successfully!" }
  end

  private

  def calendar_procedure
    @calendar_procedure ||= current_company.calendar_procedures.find(params[:id])
  end

  def set_calendar_procedure
    calendar_procedure
  end

  def procedure_options
    { positions: current_company.calendar_positions.bookable.ordered.map { |p|
        { id: p.id, name: p.name, color: p.color }
      } }
  end

  def filtered_scope
    scope = current_company.calendar_procedures.ordered.includes(:calendar_position)
    scope = scope.where(calendar_position_id: params[:calendar_position_id]) if params[:calendar_position_id].present?
    scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
    scope = scope.where(lifecycle_status: params[:lifecycle_status]) if params[:lifecycle_status].present?

    term = params[:q].to_s.strip
    return scope if term.blank?

    scope.where("#{TABLE}.name ILIKE :q OR #{TABLE}.code ILIKE :q",
      q: "%#{ActiveRecord::Base.sanitize_sql_like(term)}%")
  end

  def record_params
    params.require(:calendar_procedure).permit(
      :name, :description, :code, :slug, :duration_minutes,
      :buffer_before_minutes, :buffer_after_minutes, :min_lead_minutes, :color,
      :requires_location, :requires_equipment, :requires_practitioners,
      :calendar_position_id, :branch_id, :source_type, :source_id, :lifecycle_status
    )
  end
end
