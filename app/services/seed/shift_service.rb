class Seed::ShiftService
  def self.create(company:, branch: nil, name:, start_time:, end_time:)
    Shift.create!(
      company: company,
      branch: branch,
      name: name,
      description: "#{name} shift (#{start_time} - #{end_time})",
      start_time: start_time,
      end_time: end_time
    )
  end
end
