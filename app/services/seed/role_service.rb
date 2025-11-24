# This service seeds the database with Role records, ensuring each role
# is associated with an existing Company. It uses the enums defined in the Role model
# and simulates soft deletion.

class Seed::RoleService

  # Configuration for the number of roles per company
  ROLES_PER_COMPANY = 4
  
  def self.run    
    # Get the defined enum keys for random assignment
    statuses = Role.statuses.keys
    kinds = Role.kinds.keys

    puts "Seeding Role records..."
    
    Company.all.each do |company|
      ROLES_PER_COMPANY.times do |i|
        # Randomly assign kind and status
        random_kind = kinds.sample
        random_status = statuses.sample
        
        # Randomly discard about 1 in 8 records
        should_discard = rand(8) == 0
        
        Role.create!(
          company: company,
          name: "Role #{i}",
          description: Faker::Lorem.sentence(word_count: 8), 
          kind: random_kind, 
          status: random_status,
          # Set a random discarded_at time if the record should be discarded
          discarded_at: should_discard ? Time.zone.now - rand(1..60).days : nil
        )
      end
    end

    puts "Successfully created #{Role.count} Role records."
  end

  def self.create(
    company:,
    name:,
    description: Faker::Lorem.sentence(word_count: 8),
    business_type: Role.business_types.keys.sample,
    status: Role.statuses.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(8) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..60).days : nil

    Role.create!(
      company: company,
      name: name,
      description: description,
      business_type: business_type,
      status: status,
      discarded_at: discarded_at
    )
  end
end
