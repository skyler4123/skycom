# app/controllers/companies/company_ticket_logs_controller.rb
#
# Ticket audit trail (read-only, like table_config_logs / event_config_logs).
# Scoped to CompanyTicket.visible_to — a hidden ticket's trail is a 404.
# Serves Stimulus: Companies_CompanyTickets_ShowController (logs section)
# Endpoints: GET /companies/:company_id/company_ticket_logs(.json),
#            GET /companies/:company_id/company_ticket_logs/:id(.json)
# Docs: docs/superpowers/plans/2026-11-26-company-ticket-visibility.md
class Companies::CompanyTicketLogsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        visible_ticket_ids = current_company.company_tickets.visible_to(current_employee).select(:id)
        scope = current_company.company_ticket_logs.where(company_ticket_id: visible_ticket_ids)
          .includes(:actor).order(created_at: :desc)
        if params[:company_ticket_id].present?
          ticket = current_company.company_tickets.visible_to(current_employee)
            .find(params[:company_ticket_id])
          scope = scope.where(company_ticket: ticket)
        end
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: {
          company_ticket_logs: @results.map { |l| format_log(l) },
          pagination: @pagy.data_hash
        }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { head :not_found }
      format.json { render json: { errors: [ "Ticket not found" ] }, status: :not_found }
    end
  end

  def show
    visible_ticket_ids = current_company.company_tickets.visible_to(current_employee).select(:id)
    log = current_company.company_ticket_logs.where(company_ticket_id: visible_ticket_ids)
      .find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company_ticket_log: format_log(log) } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { head :not_found }
      format.json { render json: { errors: [ "Ticket not found" ] }, status: :not_found }
    end
  end

  private

  def format_log(log)
    log.as_json(only: [ :id, :action, :from_status, :to_status, :note, :created_at ]).merge(
      "actor_name" => log.actor&.respond_to?(:name) ? log.actor&.name : log.actor&.try(:email)
    )
  end
end
