class Seed::TagAppointmentService
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

    TagAppointment.new(
      company: company,
      tag: tag,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
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
