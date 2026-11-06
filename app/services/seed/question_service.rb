class Seed::QuestionService
  def self.new(
    company:,
    category: nil,
    name: nil,
    description: nil,
    question_type: :single_choice,
    points: 1,
    correct_text: nil,
    options: nil
  )
    category ||= Seed::CategoryService.find_or_create_for(company: company, resource_name: "questions")

    question = Question.new(
      company: company,
      category: category,
      name: name || "Question #{Faker::Lorem.sentence(word_count: 6)}",
      description: description || Faker::Lorem.sentence(word_count: 6),
      question_type: question_type,
      points: points,
      correct_text: correct_text
    )

    build_options(question, question_type, options)
    question
  end

  def self.create(...)
    question = new(...)
    question.save!
    question
  end

  def self.build_options(question, question_type, options)
    case question_type.to_sym
    when :single_choice
      contents = options.presence || Array.new(4) { |index| "Option #{index + 1}" }
      contents.each_with_index do |option, index|
        content, correct = option_content(option, index)
        question.question_options.build(content: content, correct: correct, position: index)
      end
    when :true_false
      question.question_options.build(content: "True", correct: true, position: 0)
      question.question_options.build(content: "False", correct: false, position: 1)
    when :text
      question.correct_text ||= "Model answer"
    end
  end

  def self.option_content(option, index)
    if option.is_a?(Hash)
      content = option[:content] || option["content"]
      correct = option.key?(:correct) ? option[:correct] : (option.key?("correct") ? option["correct"] : index.zero?)
      [ content, correct ]
    else
      [ option.to_s, index.zero? ]
    end
  end
  private_class_method :option_content
end
