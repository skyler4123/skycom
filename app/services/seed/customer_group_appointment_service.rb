# This service seeds the database with CustomerGroup records. Each group is
# associated with a Company and can be used to organize customers.

class Seed::CustomerGroupAppointmentService
  def self.create(
    customer_group:,
    appoint_to:,
    name: Faker::Commerce.department,
    description: "Appointment of #{appoint_to.class.name} to #{customer_group.name}"
  )
    CustomerGroupAppointment.create!(
      customer_group: customer_group,
      appoint_to: appoint_to,
      name: name,
      description: description
  )
  end
end