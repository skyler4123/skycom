# This service seeds the database with TaskGroup records. Each group is
# associated with a Company and can be used to organize tasks.

class Seed::TaskGroupService
  def self.create(
    company:,
    name: "#{Faker::Verb.base.capitalize} Tasks",
    description: "A group for #{Faker::Hacker.ingverb} tasks.",
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    TaskGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "TG-#{company.id}-#{SecureRandom.hex(3).upcase}",
      status: status || TaskGroup.statuses.keys.sample,
      business_type: business_type || TaskGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
