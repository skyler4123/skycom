# app/controllers/companies/my_exams_controller.rb
#
# Employee self-service exam list/detail/start. Every lookup is scoped through
# current_employee; the policy allows any signed-in employee.
# Serves Stimulus: Companies_MyExams_IndexController, Companies_MyExams_ShowController
# Endpoints: GET /companies/:company_id/my_exams(.json),
#            GET /companies/:company_id/my_exams/:id(.json),
#            POST /companies/:company_id/my_exams/:id/start
# Docs: docs/EXAMS.md
class Companies::MyExamsController < Companies::ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :exam_not_found

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        appointments = current_employee.employee_exam_appointments
          .includes(:exam)
          .where.not(workflow_status: :cancelled)
          .order(created_at: :desc)

        exams = appointments.group_by(&:exam_id).values.map do |rows|
          format_my_exam(rows.first.exam, rows)
        end

        render json: { exams: exams }
      end
    end
  end

  def show
    exam = current_employee.exams.find(params[:id])
    rows = current_employee.employee_exam_appointments
      .where(exam: exam)
      .where.not(workflow_status: :cancelled)
      .order(:attempt_number)
      .to_a
    payload = format_my_exam(exam, rows)

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          exam: payload,
          attempts: payload[:attempts],
          attempts_used: payload[:attempts_used],
          max_attempts: payload[:max_attempts],
          can_start: payload[:can_start],
          in_progress_appointment_id: payload[:in_progress_appointment_id]
        }
      end
    end
  end

  def start
    exam = current_employee.exams.find(params[:id])
    result = Exams::StartAttemptService.call(exam: exam, employee: current_employee)

    if result[:success]
      render json: {
        appointment_id: result[:appointment].id,
        redirect_url: take_company_my_exam_appointment_path(current_company, result[:appointment]),
        message: "Exam started."
      }
    else
      payload = { errors: result[:errors] }
      if result[:active_appointment_id].present?
        payload[:redirect_url] = take_company_my_exam_appointment_path(current_company, result[:active_appointment_id])
      elsif result[:submitted_appointment_id].present?
        payload[:redirect_url] = company_my_exam_appointment_path(current_company, result[:submitted_appointment_id])
      end
      render json: payload, status: :unprocessable_content
    end
  end

  private

  def format_my_exam(exam, rows)
    ordered = rows.sort_by(&:attempt_number)
    in_progress = ordered.find(&:workflow_status_in_progress?)
    assigned = ordered.find(&:workflow_status_assigned?)
    attempts_used = ordered.size
    pending_review = ordered.any?(&:workflow_status_submitted?)
    can_start = exam.published? && ordered.any? && in_progress.nil? && !pending_review &&
      (assigned.present? || exam.max_attempts.nil? || attempts_used < exam.max_attempts)

    {
      id: exam.id,
      name: exam.name,
      description: exam.description,
      duration_minutes: exam.duration_minutes,
      passing_score: exam.passing_score,
      max_attempts: exam.max_attempts,
      workflow_status: exam.workflow_status,
      questions_count: exam.exam_question_appointments.size,
      attempts: ordered.map { |appointment| format_attempt(appointment) },
      attempts_used: attempts_used,
      best_score: ordered.select(&:workflow_status_graded?).map(&:score).compact.max,
      can_start: can_start,
      in_progress_appointment_id: in_progress&.id,
      assigned_appointment_id: assigned&.id,
      latest_appointment: ordered.last && format_attempt(ordered.last)
    }
  end

  def format_attempt(appointment)
    {
      id: appointment.id,
      attempt_number: appointment.attempt_number,
      workflow_status: appointment.workflow_status,
      score: appointment.score,
      passed: appointment.passed,
      started_at: appointment.started_at,
      deadline_at: appointment.deadline_at,
      submitted_at: appointment.submitted_at,
      graded_at: appointment.graded_at
    }
  end

  def exam_not_found
    respond_to do |format|
      format.html { head :not_found }
      format.json { render json: { errors: [ "Exam not found" ] }, status: :not_found }
    end
  end
end
