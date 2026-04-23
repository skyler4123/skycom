class Seed::AnswerService
  def self.new(
    question:,
    content: nil,
    description: nil,
    status: nil,
    discarded_at: nil
  )
    Answer.new(
      question: question,
      content: content || Faker::Lorem.sentence(word_count: 10),
      description: description || Faker::Lorem.sentence(word_count: 5),
      status: status || Answer.statuses.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    answer = new(...)
    answer.save!
    answer
  end
end
