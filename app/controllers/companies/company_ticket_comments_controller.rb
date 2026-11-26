# app/controllers/companies/company_ticket_comments_controller.rb
#
# Help Center comment creation (Shell-First JSON only). Comments ride on the
# ticket show payload — there is no standalone index here.
# The ticket lookup runs through CompanyTicket.visible_to, so a hidden ticket
# is a 404 even for an employee with comment permission. The socket event
# carries only the ticket id; detail pages refetch through the scoped show.
# Serves Stimulus: Companies_CompanyTickets_ShowController (comment form)
# Endpoints: POST /companies/:company_id/company_ticket_comments(.json)
# Docs: docs/superpowers/plans/2026-11-26-company-ticket-visibility.md
class Companies::CompanyTicketCommentsController < Companies::ApplicationController
  def create
    ticket = current_company.company_tickets.visible_to(current_employee)
      .find(comment_params[:company_ticket_id])

    comment = CompanyTicketComment.create_for!(
      ticket: ticket,
      author: current_employee,
      message: comment_params[:message],
      files: comment_params[:file_attachments]
    )

    full_comment = format_comment(comment)
    WEBSOCKET.publish_event(
      channel: WEBSOCKET.channel_name(:company, current_company.id),
      event_key: :company_ticket_commented,
      data: { id: ticket.id }
    )
    render json: { company_ticket_comment: full_comment },
      status: :created
  rescue ActionController::ParameterMissing
    render json: { errors: [ "comment message is required" ] }, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Ticket not found" ] }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  private

  def comment_params
    params.require(:company_ticket_comment).permit(:company_ticket_id, :message, file_attachments: [])
  end

  def format_comment(comment)
    comment.as_json(only: [ :id, :message, :author_type, :author_id, :created_at ]).merge(
      "author_name" => comment.author.respond_to?(:name) ? comment.author.name : comment.author.try(:email),
      "attachments" => comment.display_attachments.map { |a| format_attachment(a) }
    )
  end

  def format_attachment(attachment)
    {
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
