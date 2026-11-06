# app/controllers/companies/my_exam_appointments_controller.rb
#
# Employee self-service attempt pages: take, autosave, submit, result.
# Every lookup is scoped through current_employee; the take payload never
# includes correct answers or awarded points.
# Serves Stimulus: Companies_MyExamAppointments_TakeController,
#                  Companies_MyExamAppointments_ShowController
# Endpoints: GET /companies/:company_id/my_exam_appointments/:id(.json),
#            GET .../take, PATCH .../answer, POST .../submit
# Docs: docs/EXAMS.md
class Companies::MyExamAppointmentsController < Companies::ApplicationController
  before_action :set_appointment, only: %i[show take answer submit]

  rescue_from ActiveRecord::RecordNotFound, with: :appointment_not_found

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        if appointment.workflow_status_in_progress?
          render json: { redirect_url: take_company_my_exam_appointment_path(current_company, appointment) }
        else
          render json: result_payload
        end
      end
    end
  end

  def take
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        if appointment.workflow_status_assigned?
          return render json: {
            redirect_url: company_my_exam_path(current_company, appointment.exam_id),
            message: "Start the exam first."
          }
        end

        if appointment.expired_by_time?
          Exams::ExpireAttemptService.call(appointment: appointment)
          return render json: {
            redirect_url: company_my_exam_appointment_path(current_company, appointment),
            message: "Time is up."
          }
        end

        unless appointment.workflow_status_in_progress?
          return render json: { redirect_url: company_my_exam_appointment_path(current_company, appointment) }
        end

        questions = appointment.employee_question_appointments.order(:position).map { |answer| take_question(answer) }

        render json: {
          appointment: take_appointment,
          exam: take_exam,
          questions: questions,
          deadline_at: appointment.deadline_at,
          remaining_seconds: appointment.time_remaining_seconds,
          answered_count: questions.count { |question| question[:selected_option_ids].any? || question[:text_answer].present? },
          total_count: questions.size
        }
      end
    end
  end

  def answer
    result = Exams::SaveAnswerService.call(
      appointment: appointment,
      answer_id: params[:answer_id],
      selected_option_ids: params[:selected_option_ids],
      text_answer: params[:text_answer]
    )

    if result[:success]
      answers = appointment.employee_question_appointments
      render json: {
        saved: true,
        answered_count: answers.count(&:answered?),
        total_count: answers.size
      }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def submit
    result = Exams::SubmitAttemptService.call(appointment: appointment, answers: params[:answers] || [])

    if result[:success]
      render json: {
        appointment: result_appointment,
        redirect_url: company_my_exam_appointment_path(current_company, appointment),
        message: submit_message
      }
    else
      payload = { errors: result[:errors] }
      payload[:redirect_url] = company_my_exam_appointment_path(current_company, appointment) if result[:expired]
      render json: payload, status: :unprocessable_content
    end
  end

  private

  attr_reader :appointment

  def set_appointment
    @appointment = current_employee.employee_exam_appointments.find(params[:id])
  end

  def take_question(answer)
    snapshot = answer.question_snapshot

    {
      id: answer.id,
      position: answer.position,
      question_type: answer.question_type,
      name: snapshot["name"],
      description: snapshot["description"],
      options: snapshot_options(answer, include_correct: false),
      option_order: answer.option_order_ids,
      selected_option_ids: answer.selected_option_ids,
      text_answer: answer.text_answer
    }
  end

  def take_appointment
    {
      id: appointment.id,
      attempt_number: appointment.attempt_number,
      status: appointment.workflow_status,
      started_at: appointment.started_at,
      deadline_at: appointment.deadline_at
    }
  end

  def take_exam
    {
      id: appointment.exam.id,
      name: appointment.exam.name,
      description: appointment.exam.description,
      duration_minutes: appointment.exam.duration_minutes,
      passing_score: appointment.exam.passing_score
    }
  end

  def result_payload
    reveal_correct = appointment.workflow_status_graded? || appointment.workflow_status_expired?

    {
      appointment: result_appointment,
      exam: take_exam,
      answers: appointment.employee_question_appointments.order(:position).map do |answer|
        result_answer(answer, reveal_correct: reveal_correct)
      end,
      can_retake: appointment.can_retake?
    }
  end

  def result_appointment
    {
      id: appointment.id,
      attempt_number: appointment.attempt_number,
      status: appointment.workflow_status,
      score: appointment.score,
      passed: appointment.passed,
      started_at: appointment.started_at,
      deadline_at: appointment.deadline_at,
      submitted_at: appointment.submitted_at,
      graded_at: appointment.graded_at
    }
  end

  def result_answer(answer, reveal_correct:)
    snapshot = answer.question_snapshot

    payload = {
      id: answer.id,
      position: answer.position,
      question_type: answer.question_type,
      question: {
        name: snapshot["name"],
        description: snapshot["description"],
        options: snapshot_options(answer, include_correct: reveal_correct)
      },
      option_order: answer.option_order_ids,
      selected_option_ids: answer.selected_option_ids,
      selected_options: answer.selected_options.map { |option| { "id" => option["id"], "content" => option["content"] } },
      text_answer: answer.text_answer
    }

    if reveal_correct
      payload[:correct] = answer.correct
      payload[:points_possible] = answer.points_possible
      payload[:points_awarded] = answer.points_awarded
    end

    payload
  end

  def snapshot_options(answer, include_correct:)
    answer.snapshot_options.map do |option|
      data = {
        "id" => option["id"],
        "content" => option["content"],
        "position" => option["position"]
      }
      data["correct"] = option["correct"] if include_correct
      data
    end
  end

  def submit_message
    if appointment.workflow_status_submitted?
      "Exam submitted. Text answers are waiting for review."
    else
      "Exam submitted successfully."
    end
  end

  def appointment_not_found
    respond_to do |format|
      format.html { head :not_found }
      format.json { render json: { errors: [ "Exam attempt not found" ] }, status: :not_found }
    end
  end
end
