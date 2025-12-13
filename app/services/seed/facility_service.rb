# This service seeds the database with Facility records, ensuring each facility
# is associated with an existing Company. It uses enums if they are defined
# in the Facility model and simulates soft deletion for a portion of the records.

class Seed::FacilityService
  def self.create(
    company_group:,
    company:,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 10),
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Facility.create!(
      company_group: company_group,
      company: company,
      name: name || "#{company.name} Facility",
      description: description,
      status: status || Facility.statuses.keys.sample,
      business_type: business_type || Facility.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
