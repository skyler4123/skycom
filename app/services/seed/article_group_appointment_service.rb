class Seed::ArticleGroupAppointmentService
  def self.new(
    company:,
    article_group:,
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
    raise "Cannot create appointment: No company or article_group provided." if company.nil? || article_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{article_group.name} Appointment"

    ArticleGroupAppointment.new(
      company: company,
      article_group: article_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Article group appointment for #{article_group.name}.",
      code: code || "AGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || ArticleGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || ArticleGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || ArticleGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
