# app/controllers/companies/calendar_equipments_controller.rb
#
# Bookable devices — JSON API (Shell-First). index supports ?q= via plain SQL:
# the calendar module is deliberately isolated from the dynamic-property +
# Meilisearch stack, so there is no SearchQueryService here (docs/CALENDAR.md §2).
#
# Serves Stimulus: Companies_CalendarEquipments_IndexController (index JSON incl. q passthrough),
#                  Companies_CalendarEquipments_NewController|EditController
# Depends on BE: GET /companies/:company_id/calendar_equipments.json
# Endpoints: GET    /companies/:company_id/calendar_equipments(.json)
#            GET    /companies/:company_id/calendar_equipments/:id(.json)
#            GET    /companies/:company_id/calendar_equipments/new(.json)
#            GET    /companies/:company_id/calendar_equipments/:id/edit(.json)
#            POST   /companies/:company_id/calendar_equipments(.json)
#            PATCH  /companies/:company_id/calendar_equipments/:id(.json)
#            DELETE /companies/:company_id/calendar_equipments/:id(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarEquipmentsController < Companies::ApplicationController
  include Companies::CalendarSerializable

  TABLE = "calendar_equipments".freeze

  before_action :set_calendar_equipment, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = filtered_scope
        @pagy, records = pagy(:offset, scope, jsonapi: true)

        render json: {
          calendar_equipments: records.map { |record| format_calendar_resource(record) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_equipment: format_calendar_resource(calendar_equipment) } }
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
      format.json { render json: { calendar_equipment: format_calendar_resource(calendar_equipment) } }
    end
  end

  def create
    new_record = current_company.calendar_equipments.new(record_params)

    if new_record.save
      render json: {
        calendar_equipment: format_calendar_resource(new_record),
        message: "Equipment created successfully!"
      }
    else
      render json: { errors: new_record.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if calendar_equipment.update(record_params)
      render json: {
        calendar_equipment: format_calendar_resource(calendar_equipment),
        message: "Equipment updated successfully!"
      }
    else
      render json: { errors: calendar_equipment.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    calendar_equipment.destroy!

    render json: { message: "Equipment deleted successfully!" }
  end

  private

  def calendar_equipment
    @calendar_equipment ||= current_company.calendar_equipments.find(params[:id])
  end

  def set_calendar_equipment
    calendar_equipment
  end

  def filtered_scope
    scope = current_company.calendar_equipments.ordered
        scope = scope.where(lifecycle_status: params[:lifecycle_status]) if params[:lifecycle_status].present?
        scope = scope.where(bookable: params[:bookable] == "true") if params[:bookable].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

    term = params[:q].to_s.strip
    return scope if term.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    scope.where("#{TABLE}.name ILIKE :q OR #{TABLE}.code ILIKE :q", q: pattern)
  end

  def record_params
    params.require(:calendar_equipment).permit(:name, :description, :lifecycle_status, :code, :color, :quantity, :branch_id, :bookable, :source_type, :source_id)
  end
end
