# app/controllers/companies/workflows_controller.rb
#
# Workflows dashboard API (Shell-First) — generic process templates (Workflow +
# ordered WorkflowSteps) managed as full REST CRUD. Binding is Category-based
# (docs/PURCHASE_WORKFLOW.md): each workflow belongs to exactly one category
# (unique index, one workflow per category) — the category is the selector, so
# there is no is_default flag. Step mutations are nested attributes; step
# DELETION is not offered (WorkflowStepLog rows are the audit trail and
# reference workflow_step_id).
# Serves Stimulus: Companies_Workflows_IndexController|NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/workflows(.json) + nested CRUD
# Docs: docs/PURCHASE_WORKFLOW.md

class Companies::WorkflowsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @pagy, @results = pagy(:offset, current_company.workflows.includes(:workflow_steps, :category), jsonapi: true)
        render json: { workflows: @results.map { |w| format_workflow(w) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    workflow = current_company.workflows.includes(:workflow_steps, :category).find(params[:id])

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
    workflow = current_company.workflows.includes(:workflow_steps, :category).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { workflow: format_workflow(workflow) } }
    end
  end

  def create
    workflow = current_company.workflows.new(workflow_params)
    normalize_steps_company(workflow)

    if workflow.save
      redirect_to company_workflow_path(current_company, workflow), notice: "Workflow created successfully"
    else
      redirect_to new_company_workflow_path(current_company), alert: workflow.errors.full_messages.to_sentence
    end
  end

  def update
    workflow = current_company.workflows.find(params[:id])
    workflow.assign_attributes(workflow_params)
    normalize_steps_company(workflow)

    if workflow.save
      redirect_to company_workflow_path(current_company, workflow), notice: "Workflow updated successfully."
    else
      redirect_to edit_company_workflow_path(current_company, workflow), alert: workflow.errors.full_messages.to_sentence
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
      :name, :description, :process_type, :category_id,
      workflow_steps_attributes: [ :id, :name, :position ]
    )
  end

  # Nested WorkflowStep rows do not inherit the parent's company — WorkflowStep
  # belongs_to :company is a separate association, so stamp it explicitly.
  def normalize_steps_company(workflow)
    workflow.workflow_steps.each { |step| step.company = current_company }
  end

  def format_workflow(workflow)
    workflow.as_json(only: [
      :id, :name, :description, :code, :process_type, :category_id,
      :lifecycle_status, :workflow_status, :created_at, :updated_at
    ]).merge(
      category: workflow.category&.as_json(only: [ :id, :name ]),
      steps: workflow.workflow_steps.sort_by(&:position)
        .map { |step| step.as_json(only: [ :id, :name, :position ]) }
    )
  end
end
