# app/controllers/companies/calendar_participants_controller.rb
#
# The people appointments are booked for — JSON API (Shell-First). index supports ?q= via plain SQL:
# the calendar module is deliberately isolated from the dynamic-property +
# Meilisearch stack, so there is no SearchQueryService here (docs/CALENDAR.md §2).
#
# Serves Stimulus: Companies_CalendarParticipants_IndexController (index JSON incl. q passthrough),
#                  Companies_CalendarParticipants_NewController|EditController
# Depends on BE: GET /companies/:company_id/calendar_participants.json
# Endpoints: GET    /companies/:company_id/calendar_participants(.json)
#            GET    /companies/:company_id/calendar_participants/:id(.json)
#            GET    /companies/:company_id/calendar_participants/new(.json)
#            GET    /companies/:company_id/calendar_participants/:id/edit(.json)
#            POST   /companies/:company_id/calendar_participants(.json)
#            PATCH  /companies/:company_id/calendar_participants/:id(.json)
#            DELETE /companies/:company_id/calendar_participants/:id(.json)
# Docs: docs/CALENDAR.md
class Companies::CalendarParticipantsController < Companies::ApplicationController
  include Companies::CalendarSerializable

  TABLE = "calendar_participants".freeze

  before_action :set_calendar_participant, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = filtered_scope
        @pagy, records = pagy(:offset, scope, jsonapi: true)

        render json: {
          calendar_participants: records.map { |record| format_calendar_resource(record) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { calendar_participant: format_calendar_resource(calendar_participant) } }
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
      format.json { render json: { calendar_participant: format_calendar_resource(calendar_participant) } }
    end
  end

  def create
    new_record = current_company.calendar_participants.new(record_params)

    if new_record.save
      render json: {
        calendar_participant: format_calendar_resource(new_record),
        message: "Participant created successfully!"
      }
    else
      render json: { errors: new_record.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if calendar_participant.update(record_params)
      render json: {
        calendar_participant: format_calendar_resource(calendar_participant),
        message: "Participant updated successfully!"
      }
    else
      render json: { errors: calendar_participant.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    calendar_participant.destroy!

    render json: { message: "Participant deleted successfully!" }
  end

  private

  def calendar_participant
    @calendar_participant ||= current_company.calendar_participants.find(params[:id])
  end

  def set_calendar_participant
    calendar_participant
  end

  def filtered_scope
    scope = current_company.calendar_participants.ordered
        scope = scope.where(lifecycle_status: params[:lifecycle_status]) if params[:lifecycle_status].present?

    term = params[:q].to_s.strip
    return scope if term.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    scope.where("#{TABLE}.name ILIKE :q OR #{TABLE}.code ILIKE :q", q: pattern)
  end

  def record_params
    params.require(:calendar_participant).permit(:name, :description, :lifecycle_status, :code, :email, :phone_number, :notes, :source_type, :source_id)
  end
end
