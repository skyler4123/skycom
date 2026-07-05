# spec/factories/shift_templates.rb
FactoryBot.define do
  factory :shift_template do
    association :company
    branch { nil }

    transient do
      start_time { "09:00" }
      end_time { "18:00" }
      name { "Standard Shift" }
    end

    initialize_with do
      Seed::ShiftTemplateService.create(
        company: company,
        branch: branch,
        name: name,
        start_time: start_time,
        end_time: end_time
      )
    end
  end
end
