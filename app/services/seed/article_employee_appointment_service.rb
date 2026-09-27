class Seed::ArticleEmployeeAppointmentService
  def self.new(
    company:,
    article:,
    employee:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, article or employee provided." if company.nil? || article.nil? || employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{article.name} Appointment"

    ArticleEmployeeAppointment.new(
      company: company,
      article: article,
      employee: employee,
      name: name,
      description: description || "Article appointment for #{article.name}.",
      code: code || "ART-EMP-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
