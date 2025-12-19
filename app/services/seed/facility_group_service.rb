# This service seeds the database with FacilityGroup records. Each group is
# associated with a Company and can be used to organize facilities.

class Seed::FacilityGroupService
  # Configuration for the number of facility groups to create per company
  GROUPS_PER_COMPANY = 3

  def self.run
    puts "Seeding FacilityGroup records..."

    # Get enum keys once before the loop for efficiency.
    lifecycle_statuses = FacilityGroup.lifecycle_statuses.keys
    workflow_statuses = FacilityGroup.workflow_statuses.keys
    business_types = FacilityGroup.business_types.keys

    Company.all.each do |company|
      GROUPS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        FacilityGroup.create!(
          company: company,
          name: "#{Faker::Address.community} Group #{i + 1}",
          description: "A group for facilities in the #{Faker::Address.city_prefix} area.",
          code: "FG-#{company.id}-#{SecureRandom.hex(3).upcase}",
          lifecycle_status: lifecycle_statuses.sample,
          workflow_status: workflow_statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{FacilityGroup.count} FacilityGroup records."
  end

  def self.create(
    company:,
    name: "#{Faker::Address.community} Group",
    description: "A group for facilities in the #{Faker::Address.city_prefix} area.",
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    FacilityGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "FG-#{company.id}-#{SecureRandom.hex(3).upcase}",
      lifecycle_status: lifecycle_status || FacilityGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || FacilityGroup.workflow_statuses.keys.sample,
      business_type: business_type || FacilityGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
