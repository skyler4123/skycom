# app/controllers/companies/exams_controller.rb
#
# Exams dashboard API (Shell-First). Draft/published/archived lifecycle,
# ordered question selection, and a cached ExamSummary block. No dynamic
# property/TableConfig system is used here.
# Serves Stimulus: Companies_Exams_IndexController, Companies_Exams_ShowController,
#                  Companies_Exams_NewController, Companies_Exams_EditController,
#                  Companies_Exams_QuestionPickerController
# Endpoints: GET/POST /companies/:company_id/exams(.json),
#            GET/PATCH/DELETE /companies/:company_id/exams/:id(.json),
#            POST /companies/:company_id/exams/:id/publish|archive|refresh_summary
# Docs: docs/EXAMS.md
class Companies::ExamsController < Companies::ApplicationController
  before_action :set_exam, only: %i[show edit update destroy publish archive refresh_summary]

  rescue_from ActiveRecord::RecordNotFound, with: :exam_not_found

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.exams.includes(:exam_summary, :exam_question_appointments)
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?
        if params[:q].present?
          query = "%#{params[:q]}%"
          scope = scope.where("exams.name ILIKE :q OR exams.description ILIKE :q", q: query)
        end

        @pagy, @exams = pagy(:offset, scope.order(created_at: :desc), jsonapi: true)

        render json: {
          exams: @exams.map { |exam| format_exam(exam) },
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
          exam: format_exam(@exam),
          questions: format_exam_questions(@exam),
          summary: format_summary(@exam),
          recent_appointments: format_recent_appointments(@exam)
        }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: reference_data }
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: reference_data.merge(exam: format_exam(@exam, include_question_ids: true)) }
    end
  end

  def create
    exam = current_company.exams.new(exam_params)

    if persist_exam(exam)
      respond_to do |format|
        format.html { redirect_to company_exam_path(current_company, exam), notice: "Exam created successfully." }
        format.json { render json: { exam: format_exam(exam), message: "Exam created successfully." }, status: :created }
      end
    else
      render_errors(exam)
    end
  end

  def update
    @exam.assign_attributes(exam_params)

    if persist_exam(@exam)
      respond_to do |format|
        format.html { redirect_to company_exam_path(current_company, @exam), notice: "Exam updated successfully." }
        format.json { render json: { exam: format_exam(@exam), message: "Exam updated successfully." } }
      end
    else
      render_errors(@exam)
    end
  end

  def destroy
    if @exam.employee_exam_appointments.exists?
      return render json: { errors: [ "This exam has attempts. Archive it instead of deleting." ] },
        status: :unprocessable_content
    end

    @exam.destroy!
    respond_to do |format|
      format.html { redirect_to company_exams_path(current_company), notice: "Exam deleted successfully." }
      format.json { render json: { message: "Exam deleted successfully." } }
    end
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey
    render json: { errors: [ "Exam could not be deleted because it is in use." ] }, status: :unprocessable_content
  end

  def publish
    @exam.publish!
    render json: { exam: format_exam(@exam.reload), message: "Exam published successfully." }
  rescue ActiveRecord::RecordInvalid
    render json: { errors: @exam.errors.full_messages }, status: :unprocessable_content
  end

  def archive
    @exam.archive!
    render json: { exam: format_exam(@exam.reload), message: "Exam archived successfully." }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  def refresh_summary
    Exams::SummaryJob.perform_later(@exam.id)
    render json: { message: "Summary refresh queued." }
  end

  private

  def set_exam
    @exam = current_company.exams.find(params[:id])
  end

  def persist_exam(exam)
    ActiveRecord::Base.transaction do
      exam.save!
      sync_questions(exam)
      exam.exam_question_appointments.reload
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @persist_errors = e.record.errors.full_messages
    false
  end

  def exam_params
    permitted = params.require(:exam).permit(
      :name,
      :description,
      :duration_minutes,
      :passing_score,
      :max_attempts,
      :shuffle_options
    )

    permitted[:duration_minutes] = nil if permitted[:duration_minutes].blank?
    permitted[:max_attempts] = nil if permitted[:max_attempts].blank?
    permitted
  end

  def sync_questions(exam)
    ids = Array(params.dig(:exam, :question_ids)).reject(&:blank?).map(&:to_s).uniq
    valid_ids = current_company.questions.where(id: ids).pluck(:id).map(&:to_s)
    ordered_ids = ids & valid_ids

    if ordered_ids.empty?
      exam.exam_question_appointments.delete_all
    else
      exam.exam_question_appointments.where.not(question_id: ordered_ids).delete_all
    end

    ordered_ids.each_with_index do |question_id, index|
      row = exam.exam_question_appointments.find_or_initialize_by(question_id: question_id)
      row.position = index
      row.save!
    end
  end

  def reference_data
    {
      questions: current_company.questions.includes(:category, :question_options).order(:name).map do |question|
        {
          id: question.id,
          name: question.name,
          question_type: question.question_type,
          points: question.points,
          options_count: question.question_options.size,
          category: question.category&.as_json(only: [ :id, :name ])
        }
      end,
      categories: current_company.categories.where(resource_name: "questions").order(:name)
        .map { |category| category.as_json(only: [ :id, :name, :resource_name ]) },
      question_types: Question.question_types.keys.map { |key| { name: key.humanize, value: key } }
    }
  end

  def format_exam(exam, include_question_ids: false)
    summary = exam.exam_summary

    payload = exam.as_json(only: [
      :id, :name, :description, :duration_minutes, :passing_score, :max_attempts,
      :shuffle_options, :workflow_status, :published_at, :created_at, :updated_at
    ]).merge(
      "questions_count" => exam.exam_question_appointments.size,
      "assigned_count" => summary&.assigned_count || exam.employee_exam_appointments.count,
      "summary" => format_summary(exam)
    )

    if include_question_ids
      payload["question_ids"] = exam.exam_question_appointments.order(:position).pluck(:question_id)
    end

    payload
  end

  def format_summary(exam)
    summary = exam.exam_summary
    return nil unless summary

    summary.as_json(only: [
      :assigned_count, :started_count, :submitted_count, :graded_count,
      :passed_count, :failed_count, :pending_review_count, :expired_count,
      :average_score, :highest_score, :lowest_score, :pass_rate,
      :question_stats, :computed_at
    ])
  end

  def format_exam_questions(exam)
    exam.exam_question_appointments.order(:position).includes(question: :category).map do |row|
      question = row.question
      {
        id: question.id,
        name: question.name,
        description: question.description,
        question_type: question.question_type,
        points: question.points,
        position: row.position,
        options_count: question.question_options.size,
        category: question.category&.as_json(only: [ :id, :name ])
      }
    end
  end

  def format_recent_appointments(exam)
    exam.employee_exam_appointments.includes(:employee).order(created_at: :desc).limit(10).map do |appointment|
      {
        id: appointment.id,
        employee: appointment.employee.as_json(only: [ :id, :name ]),
        attempt_number: appointment.attempt_number,
        workflow_status: appointment.workflow_status,
        score: appointment.score,
        passed: appointment.passed,
        submitted_at: appointment.submitted_at,
        created_at: appointment.created_at
      }
    end
  end

  def render_errors(exam)
    errors = @persist_errors.presence || exam.errors.full_messages

    respond_to do |format|
      format.html { redirect_back fallback_location: company_exams_path(current_company), alert: errors.to_sentence }
      format.json { render json: { errors: errors }, status: :unprocessable_content }
    end
  end

  def exam_not_found
    respond_to do |format|
      format.html { head :not_found }
      format.json { render json: { errors: [ "Exam not found" ] }, status: :not_found }
    end
  end
end
