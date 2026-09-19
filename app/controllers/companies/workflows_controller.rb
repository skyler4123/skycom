# app/controllers/companies/workflows_controller.rb
#
# Workflows dashboard API (Shell-First) — generic process templates (Workflow +
# ordered WorkflowSteps) managed as full REST CRUD. Setting is_default on one
# workflow demotes the previous default of the same process type (single-default
# rule in Workflow#only_one_default_per_process). Step mutations are nested
# attributes; step DELETION is not offered (WorkflowStepLog rows are the audit
# trail and reference workflow_step_id).
# Serves Stimulus: Companies_Workflows_IndexController|NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/workflows(.json) + nested CRUD
# Docs: docs/PURCHASE_WORKFLOW.md

class Companies::WorkflowsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @pagy, @results = pagy(:offset, current_company.workflows.includes(:workflow_steps), jsonapi: true)
        render json: { workflows: @results.map { |w| format_workflow(w) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    workflow = current_company.workflows.includes(:workflow_steps).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { workflow: format_workflow(workflow) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    workflow = current_company.workflows.includes(:workflow_steps).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { workflow: format_workflow(workflow) } }
    end
  end

  def create
    workflow = current_company.workflows.new(workflow_params)
    normalize_steps_company(workflow)

    begin
      ActiveRecord::Base.transaction do
        demote_other_defaults(workflow)
        workflow.save!
      end
      redirect_to company_workflow_path(current_company, workflow), notice: "Workflow created successfully"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_company_workflow_path(current_company), alert: e.record.errors.full_messages.to_sentence
    end
  end

  def update
    workflow = current_company.workflows.find(params[:id])
    workflow.assign_attributes(workflow_params)
    normalize_steps_company(workflow)

    begin
      ActiveRecord::Base.transaction do
        demote_other_defaults(workflow)
        workflow.save!
      end
      redirect_to company_workflow_path(current_company, workflow), notice: "Workflow updated successfully."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_company_workflow_path(current_company, workflow), alert: e.record.errors.full_messages.to_sentence
    end
  end

  def destroy
    workflow = current_company.workflows.find(params[:id])
    workflow.destroy!
    redirect_to company_workflows_path(current_company), notice: "Workflow deleted."
  end

  private

  def workflow_params
    params.require(:workflow).permit(
      :name, :description, :process_type, :is_default,
      workflow_steps_attributes: [ :id, :name, :position ]
    )
  end

  # Nested WorkflowStep rows do not inherit the parent's company — WorkflowStep
  # belongs_to :company is a separate association, so stamp it explicitly.
  def normalize_steps_company(workflow)
    workflow.workflow_steps.each { |step| step.company = current_company }
  end

  # Exactly one default per (company, process_type) — demote the previous
  # default inside the same transaction as the save.
  def demote_other_defaults(workflow)
    return unless workflow.is_default?

    current_company.workflows
      .where(process_type: workflow.process_type, is_default: true)
      .where.not(id: workflow.id)
      .update_all(is_default: false)
  end

  def format_workflow(workflow)
    workflow.as_json(only: [
      :id, :name, :description, :code, :process_type, :is_default,
      :lifecycle_status, :workflow_status, :created_at, :updated_at
    ]).merge(
      steps: workflow.workflow_steps.sort_by(&:position)
        .map { |step| step.as_json(only: [ :id, :name, :position ]) }
    )
  end
end
