class Seed::ExamService
  def self.create(
    company:,
    branch: nil,
    exam_group: nil,
    name: nil,
    description: nil,
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    exam_group ||= ExamGroup.create!(company: company, branch: branch) if company
    branch ||= exam_group.branch if exam_group
    company ||= exam_group.company if exam_group

    Exam.create!(
      company: company,
      branch: branch,
      exam_group: exam_group,
      name: name || "Exam #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "EXAM-#{SecureRandom.hex(4).upcase}",
      status: status || Exam.statuses.keys.sample,
      business_type: business_type || Exam.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
