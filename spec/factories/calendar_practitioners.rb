# spec/factories/calendar_practitioners.rb
FactoryBot.define do
  factory :calendar_practitioner do
    transient do
      # A CalendarPractitioner must point at a real Employee/User — the source
      # link is validated, not just a bare uuid.
      employee { association :employee }
    end

    company { employee.company }
    calendar_position { association :calendar_position, company: company }
    branch { employee.branch }

    source_type { "Employee" }
    source_id { employee.id }
    name { employee.name }
    color { nil }
    bookable { true }
  end
end
