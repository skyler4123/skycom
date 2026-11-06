# app/controllers/companies/exam_appointments_controller.rb
#
# Manager-facing attempt list, attempt detail, and text grading for one exam.
# Serves Stimulus: Companies_ExamAppointments_IndexController,
#                  Companies_ExamAppointments_ShowController
# Endpoints: GET /companies/:company_id/exams/:exam_id/appointments(.json),
#            GET /companies/:company_id/exams/:exam_id/appointments/:id(.json),
#            PATCH .../appointments/:id/grade
# Docs: docs/EXAMS.md
class Companies::ExamAppointmentsController < Companies::ApplicationController
  before_action :set_exam
  before_action :set_appointment, only: %i[show grade]

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = @exam.employee_exam_appointments.includes(:employee).order(created_at: :desc)
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?
        if params[:q].present?
          query = "%#{params[:q]}%"
          scope = scope.joins(:employee).where("employees.name ILIKE :q OR employees.email ILIKE :q", q: query)
        end

        @pagy, @appointments = pagy(:offset, scope, jsonapi: true)

        render json: {
          exam: exam_summary,
          appointments: @appointments.map { |appointment| format_appointment(appointment) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          exam: exam_summary,
          appointment: format_appointment(@appointment, include_answers: true)
        }
      end
    end
  end

  def grade
    result = Exams::GradeAttemptService.call(
      appointment: @appointment,
      grades: params[:grades],
      grader: current_employee
    )

    if result[:success]
      render json: {
        message: "Grades saved successfully.",
        appointment: format_appointment(@appointment.reload, include_answers: true)
      }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def set_exam
    @exam = current_company.exams.find(params[:exam_id])
  end

  def set_appointment
    @appointment = @exam.employee_exam_appointments.find(params[:id])
  end

  def exam_summary
    {
      id: @exam.id,
      name: @exam.name,
      workflow_status: @exam.workflow_status,
      passing_score: @exam.passing_score,
      duration_minutes: @exam.duration_minutes
    }
  end

  def format_appointment(appointment, include_answers: false)
    payload = {
      id: appointment.id,
      employee: appointment.employee.as_json(only: [ :id, :name, :email ]),
      attempt_number: appointment.attempt_number,
      status: appointment.workflow_status,
      score: appointment.score,
      passed: appointment.passed,
      started_at: appointment.started_at,
      deadline_at: appointment.deadline_at,
      submitted_at: appointment.submitted_at,
      graded_at: appointment.graded_at,
      can_grade: appointment.workflow_status_submitted?
    }

    if include_answers
      payload[:answers] = appointment.employee_question_appointments.order(:position).map { |answer| format_answer(answer) }
    end

    payload
  end

  def format_answer(answer)
    snapshot = answer.question_snapshot

    {
      id: answer.id,
      position: answer.position,
      question_type: answer.question_type,
      question: {
        name: snapshot["name"],
        description: snapshot["description"],
        correct_text: snapshot["correct_text"],
        options: snapshot["options"] || []
      },
      option_order: answer.option_order_ids,
      selected_option_ids: answer.selected_option_ids,
      selected_options: answer.selected_options.map { |option| { id: option["id"], content: option["content"] } },
      text_answer: answer.text_answer,
      correct: answer.correct,
      points_possible: answer.points_possible,
      points_awarded: answer.points_awarded
    }
  end

  def not_found
    respond_to do |format|
      format.html { head :not_found }
      format.json { render json: { errors: [ "Exam attempt not found" ] }, status: :not_found }
    end
  end
end
