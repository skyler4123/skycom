# This service seeds the database with CustomerGroup records. Each group is
# associated with a Company and can be used to organize customers.

class Seed::CustomerGroupAppointmentService
  def self.create(
    company:,
    customer_group:,
    appoint_to:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    case appoint_to
    when Customer
      Seed::CustomerCustomerGroupAppointmentService.create(
        company: company,
        customer: appoint_to,
        customer_group: customer_group,
        name: name || Faker::Commerce.department,
        description: description || Faker::Lorem.sentence(word_count: 15),
        code: code,
        discarded_at: discarded_at
      )
    when Service
      Seed::CustomerGroupServiceAppointmentService.create(
        company: company,
        customer_group: customer_group,
        service: appoint_to,
        name: name || Faker::Commerce.department,
        description: description || Faker::Lorem.sentence(word_count: 15),
        code: code,
        discarded_at: discarded_at
      )
    else
      raise "Cannot route CustomerGroupAppointment for #{appoint_to.class.name}: no atomic pair table."
    end
  end
end
