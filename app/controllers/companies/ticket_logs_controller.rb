# app/controllers/companies/ticket_logs_controller.rb
class Companies::TicketLogsController < Companies::ApplicationController
  def index
    ticket = current_company.tickets.find(params[:ticket_id]) if params[:ticket_id].present?
    scope = current_company.ticket_logs.includes(:actor, :ticket).order(created_at: :desc)
    scope = scope.where(ticket: ticket) if ticket
    @pagy, @results = pagy(:offset, scope, jsonapi: true)
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { ticket_logs: @results.map { |l| format_log(l) }, pagination: @pagy.data_hash } }
    end
  end

  def show
    log = current_company.ticket_logs.includes(:actor, :ticket).find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { ticket_log: format_log(log) } }
    end
  end

  private

  def format_log(log)
    log.as_json(only: [ :id, :action, :from_status, :to_status, :note, :created_at ]).merge(
      "actor_name" => log.actor.respond_to?(:name) && log.actor.name.present? ? log.actor.name : log.actor.try(:email),
      "ticket_id" => log.ticket_id
    )
  end
end
