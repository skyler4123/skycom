class Seed::SubscriptionGroupAppointmentService
  def self.create(
    company:,
    subscription_group:,
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
    raise "Cannot create appointment: No company or subscription_group provided." if company.nil? || subscription_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{subscription_group.name} Appointment"

    SubscriptionGroupAppointment.create!(
      company: company,
      subscription_group: subscription_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Subscription group appointment for #{subscription_group.name}.",
      code: code || "SGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || SubscriptionGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || SubscriptionGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || SubscriptionGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
