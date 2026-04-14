class Seed::AnswerService
  def self.create(
    question:,
    content: nil,
    description: nil,
    status: nil,
    discarded_at: nil
  )
    Answer.create!(
      question: question,
      content: content || Faker::Lorem.sentence(word_count: 10),
      description: description || Faker::Lorem.sentence(word_count: 5),
      status: status || Answer.statuses.keys.sample,
      discarded_at: discarded_at
    )
  end
end
