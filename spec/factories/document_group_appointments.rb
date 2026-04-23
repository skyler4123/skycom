# spec/factories/document_group_appointments.rb
FactoryBot.define do
  factory :document_group_appointment do
    association :company
    association :document_group
    association :appoint_to, factory: :employee

    name { "#{document_group.name} Appointment" }
    description { "Document group appointment for #{document_group.name}." }
    code { "DGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { DocumentGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { DocumentGroupAppointment.workflow_statuses.keys.sample }
    business_type { DocumentGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::DocumentGroupAppointmentService.new(
        company: company,
        document_group: document_group,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end
  end
end
