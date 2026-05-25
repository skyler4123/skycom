# spec/factories/project_group_appointments.rb
FactoryBot.define do
  factory :project_group_appointment do
    association :company
    association :project_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ProjectGroupAppointmentService.new(company: company, project_group: project_group, appoint_to: appoint_to)
    end
  end
end
