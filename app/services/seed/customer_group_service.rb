# This service seeds the database with CustomerGroup records. Each group is
# associated with a Company and can be used to organize customers.

class Seed::CustomerGroupService
  def self.create(
    user:,
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
      user: user,
      name: name,
      description: description,
      code: code || "CG-#{user.id}-#{SecureRandom.hex(3).upcase}",
      status: status || CustomerGroup.statuses.keys.sample,
      business_type: business_type || CustomerGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end