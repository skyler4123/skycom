# app/controllers/companies/exam_assignments_controller.rb
#
# Assignment panel API for one exam: paginated employee list with status and
# bulk assignment. Only published exams can be assigned.
# Serves Stimulus: Companies_Exams_AssignmentPanelController
# Endpoints: GET/POST /companies/:company_id/exams/:exam_id/assignments(.json)
# Docs: docs/EXAMS.md
class Companies::ExamAssignmentsController < Companies::ApplicationController
  before_action :set_exam

  rescue_from ActiveRecord::RecordNotFound, with: :exam_not_found

  def index
    scope = current_company.employees.kept.includes(:branch, :departments, :employee_groups)
    scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
    if params[:q].present?
      query = "%#{params[:q]}%"
      scope = scope.where("employees.name ILIKE :q OR employees.email ILIKE :q", q: query)
    end
    if params[:department_id].present?
      scope = scope.joins(:department_employee_appointments)
        .where(department_employee_appointments: { department_id: params[:department_id] })
    end
    if params[:employee_group_id].present?
      scope = scope.joins(:employee_employee_group_appointments)
        .where(employee_employee_group_appointments: { employee_group_id: params[:employee_group_id] })
    end

    @pagy, @employees = pagy(:offset, scope.distinct.order(:name), jsonapi: true)

    render json: {
      employees: format_employees(@employees),
      pagination: @pagy.data_hash,
      filters: filter_data
    }
  end

  def create
    result = Exams::AssignService.call(
      exam: @exam,
      employee_ids: params[:employee_ids],
      assigned_by: current_employee
    )

    if result[:success]
      render json: {
        message: assignment_message(result[:assigned_count], result[:skipped_count]),
        assigned_count: result[:assigned_count],
        skipped_count: result[:skipped_count]
      }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def set_exam
    @exam = current_company.exams.find(params[:exam_id])
  end

  def format_employees(employees)
    appointments = @exam.employee_exam_appointments
      .where(employee_id: employees.map(&:id))
      .where.not(workflow_status: :cancelled)
      .order(:attempt_number)
      .group_by(&:employee_id)

    employees.map { |employee| format_employee(employee, appointments[employee.id] || []) }
  end

  def format_employee(employee, rows)
    status, latest = assignment_status(rows)

    {
      id: employee.id,
      name: employee.name,
      email: employee.email,
      branch_id: employee.branch_id,
      branch_name: employee.branch&.name,
      departments: employee.departments.map { |department| department.as_json(only: [ :id, :name ]) },
      assignment_status: status,
      attempts_used: rows.size,
      best_score: rows.select { |row| row.workflow_status_graded? }.map(&:score).compact.max,
      latest_appointment_id: latest&.id
    }
  end

  def assignment_status(rows)
    return [ "not_assigned", nil ] if rows.empty?

    passed = rows.find { |row| row.workflow_status_graded? && row.passed == true }
    return [ "passed", passed ] if passed

    in_progress = rows.find(&:workflow_status_in_progress?)
    return [ "in_progress", in_progress ] if in_progress

    submitted = rows.find(&:workflow_status_submitted?)
    return [ "submitted", submitted ] if submitted

    assigned = rows.find(&:workflow_status_assigned?)
    return [ "assigned", assigned ] if assigned

    failed = rows.select { |row| row.workflow_status_graded? && row.passed == false }.max_by(&:attempt_number)
    return [ "failed", failed ] if failed

    expired = rows.find(&:workflow_status_expired?)
    return [ "expired", expired ] if expired

    [ "not_assigned", nil ]
  end

  def filter_data
    {
      departments: current_company.departments.order(:name).map { |department| department.as_json(only: [ :id, :name ]) },
      employee_groups: current_company.employee_groups.order(:name).map { |group| group.as_json(only: [ :id, :name ]) },
      branches: current_company.branches.order(:name).map { |branch| branch.as_json(only: [ :id, :name ]) }
    }
  end

  def assignment_message(assigned_count, skipped_count)
    base = if assigned_count.positive?
      "Assigned #{assigned_count} #{assigned_count == 1 ? 'employee' : 'employees'}."
    else
      "No new employees were assigned."
    end

    return base if skipped_count.zero?

    "#{base} #{skipped_count} already had an assignment and #{skipped_count == 1 ? 'was' : 'were'} skipped."
  end

  def exam_not_found
    render json: { errors: [ "Exam not found" ] }, status: :not_found
  end
end
