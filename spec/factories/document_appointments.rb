# spec/factories/document_appointments.rb
FactoryBot.define do
  factory :document_appointment do
    association :company
    association :document
    association :appoint_to, factory: :employee

    name { "#{document.name} Appointment" }
    description { "Document appointment for #{document.name}." }
    code { "DOC-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { DocumentAppointment.lifecycle_statuses.keys.sample }
    workflow_status { DocumentAppointment.workflow_statuses.keys.sample }
    business_type { DocumentAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::DocumentAppointmentService.new(
        company: company,
        document: document,
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
