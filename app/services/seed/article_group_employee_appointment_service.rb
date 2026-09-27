class Seed::ArticleGroupEmployeeAppointmentService
  def self.new(
    company:,
    article_group:,
    employee:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, article_group or employee provided." if company.nil? || article_group.nil? || employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{article_group.name} Appointment"

    ArticleGroupEmployeeAppointment.new(
      company: company,
      article_group: article_group,
      employee: employee,
      name: name,
      description: description || "Article group appointment for #{article_group.name}.",
      code: code || "AGE-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
