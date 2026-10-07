# app/controllers/companies/company_ticket_comments_controller.rb
#
# Help Center comment creation (Shell-First JSON only). Comments ride on the
# ticket show payload — there is no standalone index here.
# Serves Stimulus: Companies_CompanyTickets_ShowController (comment form)
# Endpoints: POST /companies/:company_id/company_ticket_comments(.json)
# Docs: docs/superpowers/plans/2026-10-07-company-support-center.md
class Companies::CompanyTicketCommentsController < Companies::ApplicationController
  def create
    ticket = current_company.company_tickets.find(comment_params[:company_ticket_id])

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
      data: { id: ticket.id, comment: full_comment, first_responded_at: ticket.reload.first_responded_at }
    )
    render json: { company_ticket_comment: full_comment },
      status: :created
  rescue ActionController::ParameterMissing
    render json: { errors: [ "comment message is required" ] }, status: :unprocessable_content
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
      "attachments" => comment.file_attachments.map { |a| format_attachment(a) }
    )
  end

  def format_attachment(attachment)
    {
      "url" => Rails.application.routes.url_helpers.rails_blob_path(
        attachment, only_path: true, disposition: "attachment"
      ),
      "filename" => attachment.filename.to_s,
      "content_type" => attachment.content_type,
      "byte_size" => attachment.byte_size,
      "image" => attachment.content_type.to_s.start_with?("image/")
    }
  end
end
