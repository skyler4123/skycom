# spec/factories/project_appointments.rb
FactoryBot.define do
  factory :project_appointment do
    association :company
    association :project
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ProjectAppointmentService.new(company: company, project: project, appoint_to: appoint_to)
    end
  end
end
