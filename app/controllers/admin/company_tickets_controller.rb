# app/controllers/admin/company_tickets_controller.rb
#
# Cross-company support pool (Shell-First). Global scope — there is NO
# current_company here; Admin::ApplicationController gates on
# super_admin/admin instead of Pundit. List page polls (never fans out to N
# company channels); the open detail subscribes to its ticket's company
# channel from the FE.
# Serves Stimulus: Admin_CompanyTickets_IndexController (pool JSON + filters),
#                  Admin_CompanyTickets_ShowController (detail + member actions)
# Endpoints: GET /admin/company_tickets(.json),
#            GET /admin/company_tickets/:id(.json),
#            POST /admin/company_tickets/:id/assign|resolve|close|reopen|comment(.json)
# Docs: docs/superpowers/plans/2026-10-07-company-support-center.md
class Admin::CompanyTicketsController < Admin::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        filter_error = enum_filter_error
        return render json: { errors: [ filter_error ] }, status: :unprocessable_content if filter_error

        scope = CompanyTicket.includes(:company, :employee, :assigned_user).order(updated_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(priority: params[:priority]) if params[:priority].present?
        scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
        scope = scope.where(assigned_user_id: nil) if params[:unassigned] == "1"

        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        open_count = Rails.sync_cache.fetch(CompanyTicket.admin_open_count_key, expires_in: 1.minute) do
          CompanyTicket.open_tickets.count
        end
        render json: {
          company_tickets: @results.map { |t| format_ticket(t) },
          pagination: @pagy.data_hash,
          open_count: open_count
        }
      end
    end
  end

  def show
    ticket = CompanyTicket.includes(
      :company, :employee, :assigned_user, { ticket_comments: :author }, { ticket_logs: :actor }
    ).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company_ticket: format_ticket_detail(ticket) } }
    end
  end

  def assign
    ticket = CompanyTicket.find(params[:id])

    begin
      ticket.assign_to!(current_user, actor: current_user)
    rescue CompanyTicket::AlreadyAssigned => e
      return render json: { errors: [ e.message ] }, status: :unprocessable_content
    end

    publish_status(ticket, from_status: ticket.status_before_last_save, to_status: "assigned")
    render json: { company_ticket: format_ticket_detail(ticket.reload) }
  end

  def resolve
    transition(params[:id], "resolved")
  end

  def close
    transition(params[:id], "closed")
  end

  def reopen
    transition(params[:id], "open")
  end

  def comment
    ticket = CompanyTicket.find(params[:id])

    begin
      message = params.require(:company_ticket_comment).permit(:message)[:message]
      comment = CompanyTicketComment.create_for!(
        ticket: ticket, author: current_user, message: message,
        files: params.dig(:company_ticket_comment, :file_attachments)
      )
    rescue ActionController::ParameterMissing
      return render json: { errors: [ "comment message is required" ] }, status: :unprocessable_content
    rescue ActiveRecord::RecordInvalid => e
      return render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
    end

    full_comment = format_comment(comment)
    WEBSOCKET.publish_event(
      channel: WEBSOCKET.channel_name(:company, ticket.company_id),
      event_key: :company_ticket_commented,
      data: { id: ticket.id, comment: full_comment, first_responded_at: ticket.reload.first_responded_at }
    )
    render json: { company_ticket_comment: full_comment },
      status: :created
  end

  private

  def transition(id, to_status)
    ticket = CompanyTicket.find(id)
    from = ticket.status
    ticket.transition_to!(to_status, actor: current_user)
    publish_status(ticket, from_status: from, to_status: ticket.status)
    render json: { company_ticket: format_ticket_detail(ticket.reload) }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  def publish_status(ticket, from_status:, to_status:)
    WEBSOCKET.publish_event(
      channel: WEBSOCKET.channel_name(:company, ticket.company_id),
      event_key: :company_ticket_status_changed,
      data: { id: ticket.id, from_status: from_status, to_status: to_status }
    )
  end

  def enum_filter_error
    if params[:status].present? && !CompanyTicket.statuses.key?(params[:status])
      return "unknown status filter"
    end
    if params[:priority].present? && !CompanyTicket.priorities.key?(params[:priority])
      return "unknown priority filter"
    end
    nil
  end

  def format_ticket(ticket)
    ticket.as_json(only: [
      :id, :name, :ticket_category, :priority, :status, :rate,
      :first_responded_at, :resolved_at, :created_at, :updated_at
    ]).merge(
      "company" => ticket.company&.as_json(only: [ :id, :name ]),
      "employee" => ticket.employee&.as_json(only: [ :id, :name ]),
      "assigned_user" => ticket.assigned_user&.as_json(only: [ :id, :name, :email ])
    )
  end

  def format_ticket_detail(ticket)
    format_ticket(ticket).merge(
      "description" => ticket.description,
      "comments" => ticket.ticket_comments.sort_by(&:created_at).map { |c| format_comment(c) },
      "logs" => ticket.ticket_logs.sort_by(&:created_at).map { |l| format_log(l) },
      "attachments" => ticket.file_attachments.map { |a| format_attachment(a) }
    )
  end

  def format_comment(comment)
    comment.as_json(only: [ :id, :message, :author_type, :author_id, :created_at ]).merge(
      "author_name" => comment.author.respond_to?(:name) && comment.author.name.present? ?
        comment.author.name : comment.author.try(:email),
      "attachments" => comment.display_attachments.map { |a| format_attachment(a) }
    )
  end

  def format_log(log)
    log.as_json(only: [ :id, :action, :from_status, :to_status, :note, :created_at ]).merge(
      "actor_name" => log.actor.respond_to?(:name) && log.actor.name.present? ?
        log.actor.name : log.actor.try(:email)
    )
  end

  def format_attachment(attachment)
    {
      # disposition: attachment forces download instead of inline render —
      # a spoofed content-type can never execute in the viewer's browser.
      # Images serve the :display variant (falls back to the blob on failure).
      "url" => attachment_url(attachment),
      "filename" => attachment.filename.to_s,
      "content_type" => attachment.content_type,
      "byte_size" => attachment.byte_size,
      "image" => attachment.content_type.to_s.start_with?("image/")
    }
  end

  def attachment_url(attachment)
    if attachment.content_type.to_s.start_with?("image/")
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
end
