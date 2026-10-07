# app/controllers/companies/company_ticket_logs_controller.rb
#
# Ticket audit trail (read-only, like table_config_logs / event_config_logs).
# Serves Stimulus: Companies_CompanyTickets_ShowController (logs section)
# Endpoints: GET /companies/:company_id/company_ticket_logs(.json),
#            GET /companies/:company_id/company_ticket_logs/:id(.json)
# Docs: docs/superpowers/plans/2026-10-07-company-support-center.md
class Companies::CompanyTicketLogsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.company_ticket_logs.includes(:actor).order(created_at: :desc)
        if params[:company_ticket_id].present?
          ticket = current_company.company_tickets.find(params[:company_ticket_id])
          scope = scope.where(company_ticket: ticket)
        end
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: {
          company_ticket_logs: @results.map { |l| format_log(l) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    log = current_company.company_ticket_logs.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company_ticket_log: format_log(log) } }
    end
  end

  private

  def format_log(log)
    log.as_json(only: [ :id, :action, :from_status, :to_status, :note, :created_at ]).merge(
      "actor_name" => log.actor&.respond_to?(:name) ? log.actor&.name : log.actor&.try(:email)
    )
  end
end
