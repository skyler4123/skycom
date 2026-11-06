class Seed::ExamService
  def self.new(
    company:,
    name: nil,
    description: nil,
    duration_minutes: 30,
    passing_score: 70,
    max_attempts: 1,
    shuffle_options: true,
    questions: []
  )
    exam = Exam.new(
      company: company,
      name: name || "Exam #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      duration_minutes: duration_minutes,
      passing_score: passing_score,
      max_attempts: max_attempts,
      shuffle_options: shuffle_options
    )

    Array(questions).each_with_index do |question, index|
      exam.exam_question_appointments.build(question: question, position: index)
    end

    exam
  end

  def self.create(...)
    exam = new(...)
    exam.save!
    exam
  end
end
