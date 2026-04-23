class Seed::QuestionService
  def self.new(
    company:,
    branch: nil,
    content: nil,
    description: nil,
    code: nil,
    status: nil,
    discarded_at: nil
  )
    Question.new(
      company: company,
      branch: branch,
      content: content || Faker::Lorem.sentence(word_count: 10),
      description: description || Faker::Lorem.sentence(word_count: 5),
      code: code || "Q-#{SecureRandom.hex(4).upcase}",
      status: status || Question.statuses.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    question = new(...)
    question.save!
    question
  end
end
