class Seed::ShiftTemplateService
  def self.create(company:, branch:, name:, start_time:, end_time:, grace_period_minutes: 15, unpaid_break_minutes: 60)
    ShiftTemplate.create!(
      company: company, branch: branch, name: name,
      start_time: start_time, end_time: end_time,
      grace_period_minutes: grace_period_minutes,
      unpaid_break_minutes: unpaid_break_minutes,
      description: "#{name} shift (#{start_time} - #{end_time})"
    )
  end
end
