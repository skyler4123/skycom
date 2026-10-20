# app/controllers/companies/ticket_comments_controller.rb
class Companies::TicketCommentsController < Companies::ApplicationController
  def create
    comment_params = params.require(:ticket_comment).permit(:ticket_id, :message, file_attachments: [])
    ticket = current_company.tickets.find(comment_params[:ticket_id])
    comment = TicketComment.create_for!(
      ticket: ticket,
      employee: current_employee,
      message: comment_params[:message],
      files: comment_params[:file_attachments]
    )

    full_comment = comment.as_json(only: [ :id, :message, :employee_id, :created_at ]).merge(
      "employee_name" => comment.employee.respond_to?(:name) ? comment.employee.name : comment.employee.try(:email)
    )

    WEBSOCKET.publish_event(
      channel: WEBSOCKET.channel_name(:company, current_company.id),
      event_key: :ticket_commented,
      data: { id: ticket.id, comment: full_comment }
    )
    render json: { ticket_comment: full_comment }, status: :created
  rescue ActionController::ParameterMissing
    render json: { errors: [ "comment message is required" ] }, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end
end
