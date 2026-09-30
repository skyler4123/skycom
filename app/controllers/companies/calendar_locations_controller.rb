# app/controllers/companies/calendar_locations_controller.rb
#
# Bookable rooms and places — JSON API (Shell-First). index supports ?q= via plain SQL:
# the calendar module is deliberately isolated from the dynamic-property +
# Meilisearch stack, so there is no SearchQueryService here (docs/CALENDAR.md §2).
#
# Serves Stimulus: Companies_CalendarLocations_IndexController (index JSON incl. q passthrough),
#                  Companies_CalendarLocations_NewController|EditController
# Depends on BE: GET /companies/:company_id/calendar_locations.json
# Endpoints: GET    /companies/:company_id/calendar_locations(.json)
#            GET    /companies/:company_id/calendar_locations/:id(.json)
#            GET    /companies/:company_id/calendar_locations/new(.json)
#            GET    /companies/:company_id/calendar_locations/:id/edit(.json)
#            POST   /companies/:company_id/calendar_locations(.json)
#            PATCH  /companies/:company_id/calendar_locations/:id(.json)
#            DELETE /companies/:company_id/calendar_locations/:id(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarLocationsController < Companies::ApplicationController
  include Companies::CalendarSerializable

  TABLE = "calendar_locations".freeze

  before_action :set_calendar_location, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = filtered_scope
        @pagy, records = pagy(:offset, scope, jsonapi: true)

        render json: {
          calendar_locations: records.map { |record| format_calendar_resource(record) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_location: format_calendar_resource(calendar_location) } }
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
      format.json { render json: { calendar_location: format_calendar_resource(calendar_location) } }
    end
  end

  def create
    new_record = current_company.calendar_locations.new(record_params)

    if new_record.save
      render json: {
        calendar_location: format_calendar_resource(new_record),
        message: "Location created successfully!"
      }
    else
      render json: { errors: new_record.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if calendar_location.update(record_params)
      render json: {
        calendar_location: format_calendar_resource(calendar_location),
        message: "Location updated successfully!"
      }
    else
      render json: { errors: calendar_location.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    calendar_location.destroy!

    render json: { message: "Location deleted successfully!" }
  end

  private

  def calendar_location
    @calendar_location ||= current_company.calendar_locations.find(params[:id])
  end

  def set_calendar_location
    calendar_location
  end

  def filtered_scope
    scope = current_company.calendar_locations.ordered
        scope = scope.where(lifecycle_status: params[:lifecycle_status]) if params[:lifecycle_status].present?
        scope = scope.where(bookable: params[:bookable] == "true") if params[:bookable].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

    term = params[:q].to_s.strip
    return scope if term.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    scope.where("#{TABLE}.name ILIKE :q OR #{TABLE}.code ILIKE :q", q: pattern)
  end

  def record_params
    params.require(:calendar_location).permit(:name, :description, :lifecycle_status, :code, :color, :capacity, :branch_id, :bookable, :source_type, :source_id)
  end
end
