# app/controllers/companies/calendar_positions_controller.rb
#
# Bookable job positions — JSON API (Shell-First). index supports ?q= via plain SQL:
# the calendar module is deliberately isolated from the dynamic-property +
# Meilisearch stack, so there is no SearchQueryService here (docs/CALENDAR.md §2).
#
# Serves Stimulus: Companies_CalendarPositions_IndexController (index JSON incl. q passthrough),
#                  Companies_CalendarPositions_NewController|EditController
# Depends on BE: GET /companies/:company_id/calendar_positions.json
# Endpoints: GET    /companies/:company_id/calendar_positions(.json)
#            GET    /companies/:company_id/calendar_positions/:id(.json)
#            GET    /companies/:company_id/calendar_positions/new(.json)
#            GET    /companies/:company_id/calendar_positions/:id/edit(.json)
#            POST   /companies/:company_id/calendar_positions(.json)
#            PATCH  /companies/:company_id/calendar_positions/:id(.json)
#            DELETE /companies/:company_id/calendar_positions/:id(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarPositionsController < Companies::ApplicationController
  include Companies::CalendarSerializable

  TABLE = "calendar_positions".freeze

  before_action :set_calendar_position, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = filtered_scope
        @pagy, records = pagy(:offset, scope, jsonapi: true)

        render json: {
          calendar_positions: records.map { |record| format_calendar_resource(record) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_position: format_calendar_resource(calendar_position) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_position: format_calendar_resource(calendar_position) } }
    end
  end

  def create
    new_record = current_company.calendar_positions.new(record_params)

    if new_record.save
      render json: {
        calendar_position: format_calendar_resource(new_record),
        message: "Position created successfully!"
      }
    else
      render json: { errors: new_record.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if calendar_position.update(record_params)
      render json: {
        calendar_position: format_calendar_resource(calendar_position),
        message: "Position updated successfully!"
      }
    else
      render json: { errors: calendar_position.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    calendar_position.destroy!

    render json: { message: "Position deleted successfully!" }
  end

  private

  def calendar_position
    @calendar_position ||= current_company.calendar_positions.find(params[:id])
  end

  def set_calendar_position
    calendar_position
  end

  def filtered_scope
    scope = current_company.calendar_positions.ordered
        scope = scope.where(lifecycle_status: params[:lifecycle_status]) if params[:lifecycle_status].present?

    term = params[:q].to_s.strip
    return scope if term.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    scope.where("#{TABLE}.name ILIKE :q OR #{TABLE}.code ILIKE :q", q: pattern)
  end

  def record_params
    params.require(:calendar_position).permit(:name, :description, :lifecycle_status, :code, :color, :default_duration_minutes, :sort_order)
  end
end
