# app/controllers/companies/tickets_controller.rb
#
# Tickets dashboard API (Shell-First). Internal issue tickets with
# category-bound workflow (docs/TICKET.md). Workflow moves only via
# `advance` (Workflows::AdvanceService — ABAC can?(:update, Ticket)).
# Serves Stimulus: Companies_Tickets_IndexController, NewController,
# ShowController, EditController.
# Endpoints: GET/POST/PATCH/DELETE /companies/:company_id/tickets(.json),
#            POST /companies/:company_id/tickets/:id/advance,
#            POST /companies/:company_id/tickets/:id/assign
class Companies::TicketsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.tickets.includes(
          :employee, :assigned_employee, :category, :workflow_step
        ).order(updated_at: :desc)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(priority: params[:priority]) if params[:priority].present?
        scope = scope.where(assigned_employee_id: params[:assigned_employee_id]) if params[:assigned_employee_id].present?
        scope = scope.where(employee: current_employee) if params[:mine].to_s == "1" && current_employee.present?

        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { tickets: format_tickets(@results), pagination: @pagy.data_hash }
      end
    end
  end

  def show
    ticket = current_company.tickets.includes(
      :employee, :assigned_employee, :category,
      { ticket_comments: :employee }, { ticket_logs: :actor },
      { workflow_step: { workflow: :workflow_steps } }
    ).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { ticket: format_ticket(ticket, with_workflow_detail: true) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          priorities: Ticket.priorities.keys,
          categories: current_company.categories.where(resource_name: "tickets").map { |c| { id: c.id, name: c.name } }
        }
      end
    end
  end

  def edit
    ticket = current_company.tickets.includes(:workflow_step).find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          ticket: format_ticket(ticket, with_workflow_detail: true),
          priorities: Ticket.priorities.keys
        }
      end
    end
  end

  def create
    ticket = current_company.tickets.new(ticket_params)
    ticket.employee ||= current_employee
    ticket.created_by_employee = current_employee

    if ticket.save
      WEBSOCKET.publish_event(
        channel: WEBSOCKET.channel_name(:company, current_company.id),
        event_key: :ticket_created,
        data: { id: ticket.id, name: ticket.name, priority: ticket.priority }
      )
      redirect_to company_ticket_path(current_company, ticket), notice: "Ticket created successfully"
    else
      redirect_to new_company_ticket_path(current_company), alert: ticket.errors.full_messages.to_sentence
    end
  end

  def update
    ticket = current_company.tickets.find(params[:id])
    ticket.assign_attributes(ticket_params)

    if ticket.save
      redirect_to company_ticket_path(current_company, ticket), notice: "Ticket updated successfully."
    else
      redirect_to edit_company_ticket_path(current_company, ticket), alert: ticket.errors.full_messages.to_sentence
    end
  end

  def destroy
    ticket = current_company.tickets.find(params[:id])
    ticket.discard
    redirect_to company_tickets_path(current_company), notice: "Ticket archived."
  end

  def advance
    ticket = current_company.tickets.find(params[:id])
    target_step = if params[:target_step_id].present?
      WorkflowStep.where(company: current_company).find_by(id: params[:target_step_id])
    end

    result = Workflows::AdvanceService.call(
      subject: ticket,
      employee: current_employee,
      outcome: params[:outcome],
      note: params[:note],
      target_step: target_step
    )

    if result[:success]
      TicketLog.create!(
        company: current_company,
        ticket: ticket,
        actor: current_employee,
        action: :workflow_step_changed,
        from_status: ticket.workflow_step&.name,
        to_status: ticket.reload.workflow_step&.name,
        note: params[:note]
      ) rescue nil
      WEBSOCKET.publish_event(
        channel: WEBSOCKET.channel_name(:company, current_company.id),
        event_key: :ticket_workflow_step_changed,
        data: { id: ticket.id }
      )
      render json: { message: "Ticket #{params[:outcome]}", ticket: format_ticket(ticket.reload, with_workflow_detail: true) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def assign
    ticket = current_company.tickets.find(params[:id])
    employee = current_company.employees.find(params[:assigned_employee_id])

    ticket.update!(assigned_employee: employee)
    TicketLog.record!(ticket: ticket, action: :assigned, actor: current_employee, note: "assigned to #{employee.name}")
    WEBSOCKET.publish_event(
      channel: WEBSOCKET.channel_name(:company, current_company.id),
      event_key: :ticket_assigned,
      data: { id: ticket.id, assigned_employee_id: employee.id }
    )
    render json: { ticket: format_ticket(ticket.reload) }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  private

  def ticket_params
    params.require(:ticket).permit(
      :name, :description, :priority, :category_id, :assigned_employee_id,
      *property_keys
    )
  end

  def property_keys
    (1..5).map { |i| "property_string_#{i}" } +
      (1..10).map { |i| "property_integer_#{i}" } +
      (1..5).map { |i| "property_decimal_#{i}" } +
      (1..5).map { |i| "property_boolean_#{i}" } +
      (1..5).map { |i| "property_datetime_#{i}" }
  end

  def format_tickets(tickets)
    tickets.map { |t| format_ticket(t) }
  end

  def format_ticket(ticket, with_workflow_detail: false)
    workflow = ticket.workflow_step&.workflow
    payload = ticket.as_json(only: [
      :id, :name, :description, :priority, :category_id,
      :assigned_employee_id, :workflow_step_id,
      :lifecycle_status, :workflow_status, :created_at, :updated_at,
      *property_keys
    ]).merge(
      "employee" => ticket.employee&.as_json(only: [ :id, :name ]),
      "assigned_employee" => ticket.assigned_employee&.as_json(only: [ :id, :name ]),
      "category" => ticket.category&.as_json(only: [ :id, :name ]),
      "workflow" => workflow&.as_json(only: [ :id, :name ]),
      "current_workflow_step" => ticket.workflow_step&.as_json(only: [ :id, :name, :position, :text_color, :background_color ])
    )

    return payload unless with_workflow_detail

    payload.merge(
      "workflow_steps" => workflow&.workflow_steps&.sort_by(&:position)&.map { |s| s.as_json(only: [ :id, :name, :position, :text_color, :background_color ]) },
      "workflow_step_logs" => ticket.workflow_step_logs.order(:created_at).map { |log|
        log.as_json(only: [ :id, :outcome, :note, :created_at ])
          .merge(step_name: log.workflow_step&.name, employee_name: log.employee&.name)
      },
      "comments" => ticket.ticket_comments.sort_by(&:created_at).map { |c| format_comment(c) },
      "logs" => ticket.ticket_logs.sort_by(&:created_at).map { |l| format_log(l) }
    )
  end

  def format_comment(comment)
    comment.as_json(only: [ :id, :message, :employee_id, :created_at ]).merge(
      "employee_name" => comment.employee.respond_to?(:name) ? comment.employee.name : comment.employee.try(:email)
    )
  end

  def format_log(log)
    log.as_json(only: [ :id, :action, :from_status, :to_status, :note, :created_at ]).merge(
      "actor_name" => log.actor.respond_to?(:name) && log.actor.name.present? ? log.actor.name : log.actor.try(:email)
    )
  end
end
