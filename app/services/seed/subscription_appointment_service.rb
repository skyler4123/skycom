class Seed::SubscriptionAppointmentService
  def self.create(
    company:,
    subscription:,
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
    raise "Cannot create appointment: No company or subscription provided." if company.nil? || subscription.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{subscription.name} Appointment"

    SubscriptionAppointment.create!(
      company: company,
      subscription: subscription,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Subscription appointment for #{subscription.name}.",
      code: code || "SUB-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || SubscriptionAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || SubscriptionAppointment.workflow_statuses.keys.sample,
      business_type: business_type || SubscriptionAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
