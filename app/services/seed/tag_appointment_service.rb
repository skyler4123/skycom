class Seed::TagAppointmentService
  # Dispatches to the atomic pairwise tag table for the target, e.g.
  # Employee => EmployeeTagAppointment, Task => TagTaskAppointment.
  def self.new(
    company:,
    tag:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
    value: nil,
    description: nil
  )
    raise "Cannot create appointment: No company or tag provided." if company.nil? || tag.nil?

    appointment_class = TagConcern.tag_appointment_class_for(appoint_to.class)

    appointment_class.new(
      company: company,
      tag: tag,
      "#{appoint_to.class.name.underscore}_id" => appoint_to.id,
      value: value || tag.value,
      description: description || "Tag appointment for #{tag.key}."
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
