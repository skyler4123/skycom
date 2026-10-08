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

    WEBSOCKET.publish_event(
      channel: WEBSOCKET.company_channel(current_company.id),
      event_key: :company_ticket_commented,
      data: { id: ticket.id, message_preview: comment.message.to_s.truncate(120), author_type: "Employee" }
    )
    render json: { company_ticket_comment: { id: comment.id, message: comment.message } },
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
end
