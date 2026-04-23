class Seed::ArticleAppointmentService
  def self.new(
    company:,
    article:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or article provided." if company.nil? || article.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{article.name} Appointment"

    ArticleAppointment.new(
      company: company,
      article: article,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Article appointment for #{article.name}.",
      code: code || "ART-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || ArticleAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || ArticleAppointment.workflow_statuses.keys.sample,
      business_type: business_type || ArticleAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
