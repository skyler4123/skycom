# This service seeds the database with Assessment records. Each assessment is
# associated with a Company.

class Seed::AssessmentService
  # Configuration for the number of assessments to create per company
  ASSESSMENTS_PER_COMPANY = 3

  def self.run
    puts "Seeding Assessment records..."

    # Get enum keys once before the loop for efficiency.
    statuses = Assessment.statuses.keys
    business_types = Assessment.business_types.keys

    Company.all.each do |company|
      ASSESSMENTS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Assessment.create!(
          company: company,
          name: "#{Faker::Job.key_skill} Assessment #{i + 1}",
          description: "Assessment for evaluating #{Faker::Company.industry} skills.",
          code: "ASSMT-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Assessment.count} Assessment records."
  end
end