class Seed::ExamGroupService
  def self.create(
    company:,
    branch: nil,
    name: nil,
    description: nil,
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    ExamGroup.create!(
      company: company,
      branch: branch,
      name: name || "ExamGroup #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "EXAMG-#{SecureRandom.hex(4).upcase}",
      status: status || ExamGroup.statuses.keys.sample,
      business_type: business_type || ExamGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
