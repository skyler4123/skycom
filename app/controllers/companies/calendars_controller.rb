# app/controllers/companies/calendars_controller.rb
#
# Calendar board API (Shell-First). index renders the day/week/month board
# shell; the JSON branch is the board feed — real Events in the requested
# range, projected to board items. Range-bounded, no pagination, no
# Meilisearch. Creation happens through Companies::EventsController
# (the board click opens its JSON create modal).
# Serves Stimulus: Companies_Calendars_IndexController
# Endpoints: GET /companies/:company_id/calendar(.json?start=&end=) — see config/routes.rb
# Docs: docs/EVENTS.md
class Companies::CalendarsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.events.where.not(start_at: nil, end_at: nil)
        scope = scope.where("start_at < ? AND end_at > ?", range_end, range_start)
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        render json: { events: scope.order(:start_at).limit(500).map { |e| board_item(e) } }
      end
    end
  end

  private

  def range_start
    params[:start]&.to_date&.beginning_of_day || Date.current.beginning_of_month
  end

  def range_end
    params[:end]&.to_date&.end_of_day || Date.current.end_of_month
  end

  def board_item(event)
    {
      id: event.id,
      title: event.name,
      start: event.start_at&.iso8601,
      end: event.end_at&.iso8601,
      workflow_status: event.workflow_status,
      allDay: false,
      extendedProps: {
        workflow_status: event.workflow_status,
        business_type: event.business_type,
        branch_id: event.branch_id,
        category_id: event.category_id
      }
    }
  end
end
