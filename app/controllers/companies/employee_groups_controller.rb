# app/controllers/companies/employee_groups_controller.rb
#
# Employee Groups dashboard API (Shell-First). index supports the same
# TableConfig-driven dynamic search/filter as other resources (?q= /
# ?filters[key]= → Meilisearch via EmployeeGroups::SearchQueryService; plain DB
# path otherwise). create/update also sync employee memberships; the selected
# manager is always enrolled as a member.
# Serves Stimulus: Companies_EmployeeGroups_IndexController (index JSON incl. q/filters passthrough),
#                  Companies_EmployeeGroups_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/employee_groups(.json) + nested CRUD — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md, docs/HR.md
class Companies::EmployeeGroupsController < Companies::ApplicationController
  before_action :ensure_employee_group_defaults, only: %i[index new]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.employee_groups.includes(:manager, :branch, :category).order(:name)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        search = EmployeeGroups::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @employee_groups_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          employee_groups: format_employee_groups(@employee_groups_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    employee_group = current_company.employee_groups
      .includes(:manager, :branch, :category, :employees)
      .find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          employee_group: format_employee_group(employee_group, include_members: true)
        }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: form_reference_data }
    end
  end

  def edit
    employee_group = current_company.employee_groups
      .includes(:manager, :branch, :category, :employees)
      .find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          employee_group: format_employee_group(employee_group, include_members: true),
          **form_reference_data
        }
      end
    end
  end

  def create
    employee_group = current_company.employee_groups.new(employee_group_params)

    ActiveRecord::Base.transaction do
      employee_group.save!
      sync_employee_memberships(employee_group)
    end

    redirect_to company_employee_group_path(current_company, employee_group),
      notice: "Employee group created successfully"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_company_employee_group_path(current_company),
      alert: e.record.errors.full_messages.to_sentence
  end

  def update
    employee_group = current_company.employee_groups.find(params[:id])

    ActiveRecord::Base.transaction do
      employee_group.update!(employee_group_params)
      sync_employee_memberships(employee_group)
    end

    redirect_to company_employee_group_path(current_company, employee_group),
      notice: "Employee group updated successfully."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_company_employee_group_path(current_company, employee_group),
      alert: e.record.errors.full_messages.to_sentence
  end

  rescue_from ActiveRecord::RecordNotFound, with: :employee_group_not_found

  private

  def ensure_employee_group_defaults
    Seed::EmployeeGroupService.ensure_defaults!(company: current_company)
  end

  def employee_group_not_found
    respond_to do |format|
      format.html { head :not_found }
      format.json do
        render json: { errors: [ "Employee group not found" ] }, status: :not_found
      end
    end
  end

  def form_reference_data
    {
      employees: current_company.employees.kept.order(:name)
        .map { |employee| employee.as_json(only: [ :id, :name, :branch_id ]) },
      branches: current_company.branches.order(:name)
        .map { |branch| branch.as_json(only: [ :id, :name ]) }
    }
  end

  # Employee ids are intentionally excluded from employee_group_params so the
  # has_many-through writer does not run before the group is saved. The raw
  # form array is read here instead, then filtered to the current tenant and
  # merged with the manager (manager membership is automatic).
  def sync_employee_memberships(employee_group)
    submitted_ids = Array(params.dig(:employee_group, :employee_ids))
      .reject(&:blank?)
      .map(&:to_s)

    submitted_ids << employee_group.manager_id.to_s if employee_group.manager_id.present?

    wanted_ids = current_company.employees.where(id: submitted_ids).pluck(:id).map(&:to_s).uniq
    appointments = employee_group.employee_employee_group_appointments
    existing_ids = appointments.pluck(:employee_id).map(&:to_s)

    appointments.where.not(employee_id: wanted_ids).destroy_all

    (wanted_ids - existing_ids).each do |employee_id|
      appointments.create!(employee_id: employee_id)
    end
  end

  def property_keys
    (1..5).map { |i| "property_string_#{i}" } +
      (1..10).map { |i| "property_integer_#{i}" } +
      (1..5).map { |i| "property_decimal_#{i}" } +
      (1..5).map { |i| "property_boolean_#{i}" } +
      (1..5).map { |i| "property_datetime_#{i}" }
  end

  def employee_group_params
    permitted = params.require(:employee_group).permit(
      :name,
      :description,
      :email,
      :code,
      :category_id,
      :branch_id,
      :manager_id,
      *property_keys
    )

    permitted.delete(:category_id) unless tenant_category?(permitted[:category_id])
    permitted.delete(:branch_id) unless tenant_branch?(permitted[:branch_id])
    permitted
  end

  def tenant_category?(category_id)
    category_id.blank? || current_company.categories.exists?(id: category_id)
  end

  def tenant_branch?(branch_id)
    branch_id.blank? || current_company.branches.exists?(id: branch_id)
  end

  def format_employee_group(employee_group, include_members: false, employees_count: nil)
    attributes = employee_group.as_json(only: [
      :id, :name, :description, :email, :code, :category_id, :branch_id, :manager_id,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at,
      *property_keys
    ]).merge(
      category: employee_group.category&.as_json(only: [ :id, :name ]),
      branch: employee_group.branch&.as_json(only: [ :id, :name ]),
      manager: employee_group.manager&.as_json(only: [ :id, :name ]),
      employees_count: employees_count || employee_group.employees.size
    )

    if include_members
      attributes[:employees] = employee_group.employees.order(:name)
        .map { |employee| employee.as_json(only: [ :id, :name ]) }
      attributes[:employee_ids] = attributes[:employees].map { |employee| employee["id"] }
    end

    attributes
  end

  def format_employee_groups(employee_groups)
    ids = employee_groups.map(&:id)
    counts = EmployeeEmployeeGroupAppointment
      .where(company_id: current_company.id, employee_group_id: ids)
      .group(:employee_group_id)
      .count

    employee_groups.map do |employee_group|
      format_employee_group(
        employee_group,
        employees_count: counts[employee_group.id] || 0
      )
    end
  end
end
