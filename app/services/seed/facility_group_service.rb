# This service seeds the database with FacilityGroup records. Each group is
# associated with a Company and can be used to organize facilities.

class Seed::FacilityGroupService
  def self.create(
    company:,
    name: "#{Faker::Address.community} Group",
    description: "A group for facilities in the #{Faker::Address.city_prefix} area.",
    code: nil,
    lifecycle_status: FacilityGroup.lifecycle_statuses.keys.sample,
    workflow_status: FacilityGroup.workflow_statuses.keys.sample,
    business_type: FacilityGroup.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    FacilityGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "FG-#{company.id}-#{SecureRandom.hex(3).upcase}",
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
