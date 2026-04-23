class Seed::ServiceGroupService
  def self.new(
    branch:,
    name: "#{Faker::App.name} Service Group",
    description: "A group for #{Faker::Company.bs} services.",
    code: nil,
    status: ServiceGroup.statuses.keys.sample,
    duration: rand(7..365),
    start_at: Faker::Date.between(from: 1.year.ago, to: Date.today).to_datetime,
    business_type: ServiceGroup.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    code ||= "SG-#{branch.id}-#{SecureRandom.hex(3).upcase}"

    ServiceGroup.new(
      branch: branch,
      name: name,
      description: description,
      code: code,
      duration: duration,
      start_at: start_at,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    group.save!
    group
  end
end
