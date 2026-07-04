class Seed::ShiftTemplateService
  def self.create(company:, branch:, name:, start_time:, end_time:, grace_period_minutes: 15, unpaid_break_minutes: 60,
                  policy_type: "fixed", full_day_minutes: 480, core_start_time: nil, core_end_time: nil)
    ShiftTemplate.create!(
      company: company, branch: branch, name: name,
      start_time: start_time, end_time: end_time,
      grace_period_minutes: grace_period_minutes,
      unpaid_break_minutes: unpaid_break_minutes,
      policy_type: policy_type, full_day_minutes: full_day_minutes,
      core_start_time: core_start_time, core_end_time: core_end_time,
      description: "#{name} shift (#{start_time} - #{end_time})"
    )
  end
end
