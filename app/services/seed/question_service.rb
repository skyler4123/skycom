class Seed::QuestionService
  def self.create(
    company:,
    branch: nil,
    content: nil,
    description: nil,
    code: nil,
    status: nil,
    discarded_at: nil
  )
    Question.create!(
      company: company,
      branch: branch,
      content: content || Faker::Lorem.sentence(word_count: 10),
      description: description || Faker::Lorem.sentence(word_count: 5),
      code: code || "Q-#{SecureRandom.hex(4).upcase}",
      status: status || Question.statuses.keys.sample,
      discarded_at: discarded_at
    )
  end
end
