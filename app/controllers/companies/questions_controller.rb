# app/controllers/companies/questions_controller.rb
#
# Question Bank API (Shell-First). Questions are company-scoped, use the
# existing Category model with resource_name "questions", and never use the
# dynamic property/TableConfig system.
# Serves Stimulus: Companies_Questions_IndexController,
#                  Companies_Questions_ShowController,
#                  Companies_Questions_NewController,
#                  Companies_Questions_EditController
# Endpoints: GET/POST /companies/:company_id/questions(.json),
#            GET/PATCH/DELETE /companies/:company_id/questions/:id(.json)
# Docs: docs/EXAMS.md
class Companies::QuestionsController < Companies::ApplicationController
  before_action :set_question, only: %i[show edit update destroy]

  rescue_from ActiveRecord::RecordNotFound, with: :question_not_found

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.questions.includes(:category, :question_options)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(question_type: params[:question_type]) if params[:question_type].present?
        if params[:q].present?
          query = "%#{params[:q]}%"
          scope = scope.where("questions.name ILIKE :q OR questions.description ILIKE :q", q: query)
        end

        @pagy, @questions = pagy(:offset, scope.order(:name), jsonapi: true)

        render json: {
          questions: @questions.map { |question| format_question(question, include_options: false) },
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
          question: format_question(@question),
          usage_count: @question.exam_question_appointments.count
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
      format.json { render json: reference_data.merge(question: format_question(@question)) }
    end
  end

  def create
    question = current_company.questions.new(question_params)

    if persist_question(question)
      respond_to do |format|
        format.html { redirect_to company_question_path(current_company, question), notice: "Question created successfully." }
        format.json { render json: { question: format_question(question), message: "Question created successfully." }, status: :created }
      end
    else
      render_errors(question)
    end
  end

  def update
    @question.assign_attributes(question_params)

    if persist_question(@question)
      respond_to do |format|
        format.html { redirect_to company_question_path(current_company, @question), notice: "Question updated successfully." }
        format.json { render json: { question: format_question(@question), message: "Question updated successfully." } }
      end
    else
      render_errors(@question)
    end
  end

  def destroy
    if @question.exam_question_appointments.exists? || @question.employee_question_appointments.exists?
      return render json: { errors: [ "Question is used by an exam or attempt; archive it instead." ] },
        status: :unprocessable_content
    end

    @question.destroy!
    respond_to do |format|
      format.html { redirect_to company_questions_path(current_company), notice: "Question deleted successfully." }
      format.json { render json: { message: "Question deleted successfully." } }
    end
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey
    render json: { errors: [ "Question could not be deleted because it is in use." ] }, status: :unprocessable_content
  end

  private

  def set_question
    @question = current_company.questions.find(params[:id])
  end

  def persist_question(question)
    ActiveRecord::Base.transaction do
      sync_options(question)
      question.question_options.reload if question.persisted?
      question.save!
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @persist_errors = e.record.errors.full_messages
    false
  end

  def question_params
    params.require(:question).permit(
      :name,
      :description,
      :category_id,
      :question_type,
      :points,
      :correct_text
    )
  end

  def sync_options(question)
    entries = option_entries

    if question.text?
      question.question_options.each(&:destroy!)
      return
    end

    correct_index = params.dig(:question, :correct_option_index).to_i
    wanted_ids = entries.map { |entry| entry[:id] }.compact.map(&:to_s)

    question.question_options.each do |option|
      option.destroy! unless wanted_ids.include?(option.id.to_s)
    end

    entries.each_with_index do |entry, index|
      option = entry[:id].present? ? question.question_options.find_by(id: entry[:id]) : question.question_options.build
      next unless option

      option.assign_attributes(
        content: entry[:content],
        position: index,
        correct: index == correct_index
      )
      option.save! if question.persisted?
    end
  end

  def option_entries
    raw = params.dig(:question, :options)
    return [] if raw.blank?

    raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
    raw = raw.values if raw.is_a?(Hash)

    Array(raw).filter_map do |entry|
      data = entry.respond_to?(:to_unsafe_h) ? entry.to_unsafe_h : (entry.respond_to?(:to_h) ? entry.to_h : entry)
      content = data[:content] || data["content"]
      next if content.blank?

      {
        id: data[:id] || data["id"],
        content: content
      }
    end
  end

  def reference_data
    categories = current_company.categories.where(resource_name: "questions").order(:name).to_a
    categories = [ Seed::CategoryService.find_or_create_for(company: current_company, resource_name: "questions") ] if categories.empty?

    {
      categories: categories.map { |category| category.as_json(only: [ :id, :name, :resource_name ]) },
      question_types: Question.question_types.keys.map { |key| { name: key.humanize, value: key } }
    }
  end

  def format_question(question, include_options: true)
    question.as_json(only: [
      :id, :name, :description, :category_id, :question_type, :points, :correct_text,
      :lifecycle_status, :created_at, :updated_at
    ]).merge(
      "category" => question.category&.as_json(only: [ :id, :name ]),
      "options_count" => question.question_options.size,
      "options" => include_options ? format_options(question) : []
    )
  end

  def format_options(question)
    question.question_options.order(:position).map do |option|
      option.as_json(only: [ :id, :content, :correct, :position ])
    end
  end

  def render_errors(question)
    errors = @persist_errors.presence || question.errors.full_messages

    respond_to do |format|
      format.html { redirect_back fallback_location: company_questions_path(current_company), alert: errors.to_sentence }
      format.json { render json: { errors: errors }, status: :unprocessable_content }
    end
  end

  def question_not_found
    respond_to do |format|
      format.html { head :not_found }
      format.json { render json: { errors: [ "Question not found" ] }, status: :not_found }
    end
  end
end
