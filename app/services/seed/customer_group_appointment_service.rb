# This service seeds the database with CustomerGroup records. Each group is
# associated with a Company and can be used to organize customers.

class Seed::CustomerGroupAppointmentService
  def self.create(
    customer_group:,
    appoint_to:,
    name: Faker::Commerce.department,
    description: Faker::Lorem.sentence(word_count: 15)
  )
    CustomerGroupAppointment.create!(
      customer_group: customer_group,
      appoint_to: appoint_to,
      name: name,
      description: description
  )
  end
end
