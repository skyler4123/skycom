# spec/factories/document_appointments.rb
FactoryBot.define do
  factory :document_appointment do
    association :company
    association :document
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::DocumentAppointmentService.new(company: company, document: document, appoint_to: appoint_to)
    end
  end
end
