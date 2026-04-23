# spec/factories/tag_appointments.rb
FactoryBot.define do
  factory :tag_appointment do
    association :company
    association :tag
    association :appoint_to, factory: :employee

    value { tag.value }
    description { "Tag appointment for #{tag.key}." }

    initialize_with do
      Seed::TagAppointmentService.new(
        company: company,
        tag: tag,
        appoint_to: appoint_to,
        value: value,
        description: description
      )
    end

  end
end
