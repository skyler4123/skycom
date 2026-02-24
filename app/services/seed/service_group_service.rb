# This service seeds the database with ServiceGroup records. Each group is
# associated with a Company and can be used to organize services.

class Seed::ServiceGroupService
  def self.create(
    company:,
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
    code ||= "SG-#{company.id}-#{SecureRandom.hex(3).upcase}"

    ServiceGroup.create!(
      company: company,
      name: name,
      description: description,
      code: codeatus,
      duration: duration,
      start_at: start_at,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
