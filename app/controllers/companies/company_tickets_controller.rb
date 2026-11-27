# app/controllers/companies/company_tickets_controller.rb
#
# Help Center B2B API (Shell-First). Company employees raise support tickets
# to Skycom; Skycom staff handle them from the Admin pool.
# Index supports enum filters (?status= / ?priority= / ?ticket_category=) + ?mine=1
# and is scoped by CompanyTicket.visible_to (company-wide + own; owner sees all).
# NOTE: ticket taxonomy is the inline `ticket_category` enum — NOT the
# Category/PropertyMapping system, so there is no `category_id` filter here.
# Status moves ONLY via CompanyTicket#transition_to! (Admin side) — `status`,
# `assigned_user`, `first_responded_at`, `resolved_at`, `company_id` and
# `employee_id` are NEVER permitted through create/rate params. Only the creator
# may change `visibility` (PATCH update).
# Serves Stimulus: Companies_CompanyTickets_IndexController (index JSON incl. filters + open_count),
#                  Companies_CompanyTickets_NewController (new reference data),
#                  Companies_CompanyTickets_ShowController (show JSON + comments + logs + visibility),
#                  rate endpoint serves the show-page rating widget
# Endpoints: GET /companies/:company_id/company_tickets(.json?status=&priority=&ticket_category=&mine=1),
#            GET /companies/:company_id/company_tickets/new(.json),
#            GET /companies/:company_id/company_tickets/:id(.json),
#            POST /companies/:company_id/company_tickets(.json),
#            PATCH /companies/:company_id/company_tickets/:id(.json),
#            POST /companies/:company_id/company_tickets/:id/rate(.json)
# Docs: docs/superpowers/plans/2026-11-26-company-ticket-visibility.md
class Companies::CompanyTicketsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        filter_error = enum_filter_error
        return render json: { errors: [ filter_error ] }, status: :unprocessable_content if filter_error

        visible = current_company.company_tickets.visible_to(current_employee)
        scope = visible.includes(:employee, :assigned_user).order(updated_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(priority: params[:priority]) if params[:priority].present?
        scope = scope.where(ticket_category: params[:ticket_category]) if params[:ticket_category].present?
        scope = scope.where(employee: current_employee) if params[:mine].to_s == "1" && current_employee.present?

        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        open_count = visible.open_tickets.count
        render json: {
          company_tickets: @results.map { |t| format_ticket(t) },
          pagination: @pagy.data_hash,
          open_count: open_count
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        begin
          ticket = current_company.company_tickets.visible_to(current_employee).includes(
            :employee, :assigned_user, { ticket_comments: :author }, { ticket_logs: :actor }
          ).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          return render json: { errors: [ "Ticket not found" ] }, status: :not_found
        end

        render json: { company_ticket: format_ticket_detail(ticket) }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          ticket_categories: CompanyTicket.ticket_categories.keys,
          priorities: CompanyTicket.priorities.keys,
          visibilities: CompanyTicket.visibilities.keys,
          default_visibility: CompanyTicket.visibilities.key(CompanyTicket.column_defaults["visibility"])
        }
      end
    end
  end

  def create
    if (visibility_error = invalid_visibility_error)
      return respond_to do |format|
        format.html do
          redirect_to new_company_company_ticket_path(current_company), alert: visibility_error
        end
        format.json do
          render json: { errors: [ visibility_error ] }, status: :unprocessable_content
        end
      end
    end

    ticket = current_company.company_tickets.new(ticket_params.merge(employee: current_employee))

    respond_to do |format|
      format.html do
        if ticket.save
          redirect_to company_company_ticket_path(current_company, ticket),
            notice: "Support ticket created successfully"
        else
          redirect_to new_company_company_ticket_path(current_company),
            alert: ticket.errors.full_messages.to_sentence
        end
      end
      format.json do
        if ticket.save
          WEBSOCKET.publish_event(
            channel: WEBSOCKET.channel_name(:company, current_company.id),
            event_key: :company_ticket_created,
            data: { id: ticket.id }
          )
          render json: { company_ticket: format_ticket_detail(ticket) }, status: :created
        else
          render json: { errors: ticket.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  end

  def update
    ticket = current_company.company_tickets.visible_to(current_employee).find(params[:id])

    unless ticket.employee_id == current_employee.id
      return render json: { errors: [ "only the ticket creator can change visibility" ] }, status: :forbidden
    end

    if (visibility_error = visibility_param_error)
      return render json: { errors: [ visibility_error ] }, status: :unprocessable_content
    end

    previous_visibility = ticket.visibility
    ticket.assign_attributes(visibility_params)

    respond_to do |format|
      if ticket.save
        if previous_visibility != ticket.visibility
          CompanyTicketLog.record!(
            ticket: ticket,
            action: :visibility_changed,
            actor: current_employee,
            from_status: previous_visibility,
            to_status: ticket.visibility
          )
        end
        format.html do
          redirect_to company_company_ticket_path(current_company, ticket),
            notice: "Visibility updated"
        end
        format.json do
          render json: {
            message: "Visibility updated",
            company_ticket: format_ticket_detail(ticket.reload)
          }
        end
      else
        format.html do
          redirect_to company_company_ticket_path(current_company, ticket),
            alert: ticket.errors.full_messages.to_sentence
        end
        format.json do
          render json: { errors: ticket.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { head :not_found }
      format.json { render json: { errors: [ "Ticket not found" ] }, status: :not_found }
    end
  end

  def rate
    ticket = current_company.company_tickets.visible_to(current_employee).find(params[:id])

    unless ticket.employee_id == current_employee.id
      return render json: { errors: [ "only the ticket creator can rate" ] }, status: :forbidden
    end

    begin
      value = params.require(:company_ticket).permit(:rate)[:rate]
      ticket.rate!(value.to_i, employee: current_employee)
    rescue ActionController::ParameterMissing
      return render json: { errors: [ "rate is required" ] }, status: :unprocessable_content
    rescue CompanyTicket::NotTicketOwner
      return render json: { errors: [ "only the ticket creator can rate" ] }, status: :forbidden
    rescue ActiveRecord::RecordInvalid => e
      return render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
    end

    WEBSOCKET.publish_event(
      channel: WEBSOCKET.channel_name(:company, current_company.id),
      event_key: :company_ticket_status_changed,
      data: { id: ticket.id }
    )
    render json: { company_ticket: format_ticket_detail(ticket.reload) }
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Ticket not found" ] }, status: :not_found
  end

  private

  def ticket_params
    params.require(:company_ticket).permit(
      :name, :description, :ticket_category, :priority, :visibility,
      file_attachments: []
    )
  end

  def visibility_params
    params.require(:company_ticket).permit(:visibility)
  end

  def invalid_visibility_error
    return nil if params.dig(:company_ticket, :visibility).blank?

    visibility_param_error
  end

  def visibility_param_error
    value = params.dig(:company_ticket, :visibility)
    return "visibility is required" if value.blank?
    return "unknown visibility" unless CompanyTicket.visibilities.key?(value.to_s)

    nil
  end

  def enum_filter_error
    if params[:status].present? && !CompanyTicket.statuses.key?(params[:status])
      return "unknown status filter"
    end
    if params[:priority].present? && !CompanyTicket.priorities.key?(params[:priority])
      return "unknown priority filter"
    end
    if params[:ticket_category].present? && !CompanyTicket.ticket_categories.key?(params[:ticket_category])
      return "unknown ticket_category filter"
    end
    nil
  end

  def format_ticket(ticket)
    ticket.as_json(only: [
      :id, :name, :ticket_category, :priority, :status, :visibility, :rate,
      :first_responded_at, :resolved_at, :created_at, :updated_at
    ]).merge(
      "employee" => ticket.employee&.as_json(only: [ :id, :name ]),
      "assigned_user" => ticket.assigned_user&.as_json(only: [ :id, :name, :email ])
    )
  end

  def format_ticket_detail(ticket)
    format_ticket(ticket).merge(
      "description" => ticket.description,
      "can_manage_visibility" => ticket.employee_id == current_employee.id,
      "can_rate" => ticket.employee_id == current_employee.id &&
        (ticket.status_resolved? || ticket.status_closed?),
      "comments" => ticket.ticket_comments.sort_by(&:created_at).map { |c| format_comment(c) },
      "logs" => ticket.ticket_logs.sort_by(&:created_at).map { |l| format_log(l) },
      "attachments" => ticket.file_attachments.map { |a| format_attachment(a) }
    )
  end

  def format_comment(comment)
    comment.as_json(only: [ :id, :message, :author_type, :author_id, :created_at ]).merge(
      "author_name" => comment_author_name(comment),
      "attachments" => comment.display_attachments.map { |a| format_attachment(a) }
    )
  end

  def format_log(log)
    log.as_json(only: [ :id, :action, :from_status, :to_status, :note, :created_at ]).merge(
      "actor_name" => log_actor_name(log)
    )
  end

  def format_attachment(attachment)
    {
      # disposition: attachment forces download instead of inline render —
      # a spoofed content-type can never execute in the viewer's browser.
      # Comment images serve the :display variant (ticket attachments keep
      # the blob path); falls back to the blob on processing failure.
      "url" => attachment_url(attachment),
      "filename" => attachment.filename.to_s,
      "content_type" => attachment.content_type,
      "byte_size" => attachment.byte_size,
      "image" => attachment.content_type.to_s.start_with?("image/")
    }
  end

  def attachment_url(attachment)
    if attachment.record_type == "CompanyTicketComment" && attachment.content_type.to_s.start_with?("image/")
      Rails.application.routes.url_helpers.rails_representation_url(
        attachment.variant(:display).processed, only_path: true
      )
    else
      Rails.application.routes.url_helpers.rails_blob_path(
        attachment, only_path: true, disposition: "attachment"
      )
    end
  rescue
    Rails.application.routes.url_helpers.rails_blob_path(
      attachment, only_path: true, disposition: "attachment"
    )
  end

  def comment_author_name(comment)
    author = comment.author
    return nil unless author
    author.respond_to?(:name) ? author.name : author.email
  end

  def log_actor_name(log)
    actor = log.actor
    return nil unless actor
    actor.respond_to?(:name) && actor.name.present? ? actor.name : actor.try(:email)
  end
end
