# frozen_string_literal: true

# Seed-only exam demo data: numbered question bank, exams across workflow
# statuses, assignments, attempts across the lifecycle, and cached summaries.
# Attempts go through the real exam services so snapshots, scoring, and
# summaries match production behavior.
class Seed::ExamSampleService
  QUESTION_COUNT = 12
  QUESTION_TYPES = %i[
    single_choice single_choice single_choice true_false single_choice text
    single_choice single_choice single_choice true_false single_choice text
  ].freeze

  def self.seed_for(company:)
    new(company: company).seed
  end

  def initialize(company:)
    @company = company
    @employees = company.employees.kept.order(:created_at, :id).to_a
    @owner = @employees.find { |employee| employee.business_type.to_s == OWNER_BUSINESS_TYPE } || @employees.first
    @staff = @employees.reject { |employee| employee.id == @owner&.id }
  end

  def seed
    return if employees.empty? || owner.nil?

    questions = create_questions
    exams = create_exams(questions)
    assign_exams(exams)
    seed_attempts(exams)
    exams.each_value { |exam| Exams::SummaryService.call(exam: exam) }
  end

  private

  attr_reader :company, :employees, :owner, :staff

  def create_questions
    question_categories = categories

    Array.new(QUESTION_COUNT) do |index|
      question_type = QUESTION_TYPES[index]

      Seed::QuestionService.create(
        company: company,
        category: question_categories[index % question_categories.length],
        name: "Question #{index + 1}",
        description: "Question title #{index + 1}",
        question_type: question_type,
        points: question_type == :text ? 2 : 1,
        correct_text: question_type == :text ? "Question answer #{index + 1}" : nil,
        options: question_type == :single_choice ? Array.new(4) { |option_index| "Question Option #{option_index + 1}" } : nil
      )
    end
  end

  def create_exams(questions)
    objective_questions = questions.reject(&:text?)
    text_questions = questions.select(&:text?)

    exam_one = create_exam(
      name: "Exam 1",
      description: "Published sample exam with objective questions.",
      duration_minutes: 30,
      max_attempts: 2,
      questions: objective_questions.first(8)
    )
    exam_one.publish!

    exam_two = create_exam(
      name: "Exam 2",
      description: "Published sample exam with text answers for manual grading.",
      duration_minutes: 45,
      max_attempts: 1,
      questions: objective_questions.first(4) + text_questions.first(2)
    )
    exam_two.publish!

    exam_three = create_exam(
      name: "Exam 3",
      description: "Published short exam assigned for self-service.",
      duration_minutes: 15,
      max_attempts: 1,
      questions: objective_questions.first(4)
    )
    exam_three.publish!

    exam_four = create_exam(
      name: "Exam 4",
      description: "Draft sample exam.",
      duration_minutes: 20,
      max_attempts: 1,
      questions: objective_questions.first(5)
    )

    exam_five = create_exam(
      name: "Exam 5",
      description: "Archived sample exam.",
      duration_minutes: 20,
      max_attempts: 1,
      questions: objective_questions.first(5)
    )
    exam_five.publish!
    exam_five.archive!

    {
      exam_one: exam_one,
      exam_two: exam_two,
      exam_three: exam_three,
      exam_four: exam_four,
      exam_five: exam_five
    }
  end

  def create_exam(name:, description:, duration_minutes:, max_attempts:, questions:)
    Seed::ExamService.create(
      company: company,
      name: name,
      description: description,
      duration_minutes: duration_minutes,
      passing_score: 70,
      max_attempts: max_attempts,
      shuffle_options: true,
      questions: questions
    )
  end

  def assign_exams(exams)
    assign_employees(exams[:exam_one], [ owner ] + staff.first(6))
    assign_employees(exams[:exam_two], [ owner ] + staff.first(4))
    assign_employees(exams[:exam_three], [ owner, staff[5] ].compact)
  end

  def assign_employees(exam, employees_to_assign)
    result = Exams::AssignService.call(
      exam: exam,
      employee_ids: employees_to_assign.map(&:id),
      assigned_by: owner
    )
    raise "Failed to assign #{exam.name}: #{result[:errors].join(', ')}" unless result[:success]
  end

  def seed_attempts(exams)
    seed_exam_one_attempts(exams[:exam_one])
    seed_exam_two_attempts(exams[:exam_two])
  end

  def seed_exam_one_attempts(exam)
    finish_attempt(exam, owner, correct_count: objective_count(exam))

    if staff[0]
      finish_attempt(exam, staff[0], correct_count: 2)
      finish_attempt(exam, staff[0], correct_count: objective_count(exam) - 1)
    end

    finish_attempt(exam, staff[1], correct_count: 1) if staff[1]
    hold_attempt(exam, staff[3]) if staff[3]
    expire_attempt(exam, staff[4]) if staff[4]
    finish_attempt(exam, staff[5], correct_count: 6) if staff[5]
    # staff[2] keeps the assigned row created by Exams::AssignService.
  end

  def seed_exam_two_attempts(exam)
    finish_attempt(exam, staff[0], correct_count: 2) if staff[0]
    finish_attempt(exam, staff[1], correct_count: 4, text_points: [ 2, 2 ]) if staff[1]
    finish_attempt(exam, staff[2], correct_count: 1, text_points: [ 1, 1 ]) if staff[2]
    hold_attempt(exam, owner)
    # staff[3] keeps the assigned row created by Exams::AssignService.
  end

  def finish_attempt(exam, employee, correct_count:, text_points: nil)
    appointment = start_attempt(exam, employee)
    answers = appointment.employee_question_appointments.reload.to_a
    objective_answers = answers.reject(&:text?)
    correct_count = correct_count.clamp(0, objective_answers.size)

    objective_answers.each_with_index do |answer, index|
      option_id = index < correct_count ? answer.correct_option_ids.first : wrong_option_id(answer)
      save_answer(appointment, answer, selected_option_ids: [ option_id ])
    end

    answers.select(&:text?).each do |answer|
      save_answer(
        appointment,
        answer,
        text_answer: answer.question_snapshot["correct_text"].presence || "Sample text answer"
      )
    end

    result = Exams::SubmitAttemptService.call(appointment: appointment)
    raise "Failed to submit #{exam.name} for employee #{employee.id}: #{result[:errors].join(', ')}" unless result[:success]

    grade_text_answers(appointment, text_points) if text_points
    appointment
  end

  def hold_attempt(exam, employee)
    appointment = start_attempt(exam, employee)
    appointment.update!(deadline_at: 2.hours.from_now) if appointment.deadline_at.present?
    appointment
  end

  def expire_attempt(exam, employee)
    appointment = start_attempt(exam, employee)
    appointment.update_columns(started_at: 1.hour.ago, deadline_at: 30.minutes.ago)
    appointment.reload

    result = Exams::ExpireAttemptService.call(appointment: appointment)
    raise "Failed to expire #{exam.name} for employee #{employee.id}: #{result[:errors].join(', ')}" unless result[:success]

    result[:appointment]
  end

  def start_attempt(exam, employee)
    result = Exams::StartAttemptService.call(exam: exam, employee: employee)
    raise "Failed to start #{exam.name} for employee #{employee.id}: #{result[:errors].join(', ')}" unless result[:success]

    result[:appointment]
  end

  def save_answer(appointment, answer, selected_option_ids: nil, text_answer: nil)
    result = Exams::SaveAnswerService.call(
      appointment: appointment,
      answer_id: answer.id,
      selected_option_ids: selected_option_ids,
      text_answer: text_answer
    )
    raise "Failed to save answer #{answer.id}: #{result[:errors].join(', ')}" unless result[:success]
  end

  def grade_text_answers(appointment, text_points)
    appointment.reload
    text_answers = appointment.employee_question_appointments.select(&:text?)
    grades = text_answers.each_with_index.to_h do |answer, index|
      [ answer.id, text_points[index] || answer.points_possible ]
    end

    result = Exams::GradeAttemptService.call(appointment: appointment, grades: grades, grader: owner)
    raise "Failed to grade #{appointment.exam.name}: #{result[:errors].join(', ')}" unless result[:success]
  end

  def objective_count(exam)
    exam.questions.reject(&:text?).size
  end

  def wrong_option_id(answer)
    correct_id = answer.correct_option_ids.first.to_s
    answer.snapshot_options.find { |option| option["id"].to_s != correct_id }&.fetch("id")
  end

  def categories
    question_categories = company.categories.where(resource_name: "questions").order(:name).to_a
    return question_categories if question_categories.any?

    [ Seed::CategoryService.find_or_create_for(company: company, resource_name: "questions") ]
  end
end
