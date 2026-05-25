# spec/factories/document_group_appointments.rb
FactoryBot.define do
  factory :document_group_appointment do
    association :company
    association :document_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::DocumentGroupAppointmentService.new(company: company, document_group: document_group, appoint_to: appoint_to)
    end
  end
end
