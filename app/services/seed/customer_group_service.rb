# This service seeds the database with CustomerGroup records. Each group is
# associated with a Company and can be used to organize customers.

class Seed::CustomerGroupService
  # Configuration for the number of customer groups to create per company
  GROUPS_PER_COMPANY = 3

  def self.run
    puts "Seeding CustomerGroup records..."

    # Get enum keys once before the loop for efficiency.
    statuses = CustomerGroup.statuses.keys
    business_types = CustomerGroup.business_types.keys

    Company.all.each do |company|
      GROUPS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        CustomerGroup.create!(
          company: company,
          name: "#{Faker::Commerce.department} Customers #{i + 1}",
          description: "A group for #{Faker::Marketing.buzzwords} customers.",
          code: "CG-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{CustomerGroup.count} CustomerGroup records."
  end

  def self.create(
    company: Company.all.sample,
    name: "#{Faker::Commerce.department} Customers",
    description: "A group for #{Faker::Marketing.buzzwords} customers.",
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    CustomerGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "CG-#{company.id}-#{SecureRandom.hex(3).upcase}",
      status: status || CustomerGroup.statuses.keys.sample,
      business_type: business_type || CustomerGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end