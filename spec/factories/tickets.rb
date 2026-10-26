FactoryBot.define do
  factory :ticket do
    association :company
    association :employee, factory: :employee
    category { Seed::CategoryService.find_or_create_for(company: company, resource_name: "tickets") rescue nil }
    name { "Ticket #{SecureRandom.hex(4)}" }

    initialize_with do
      Seed::TicketService.new(company: company, employee: employee, name: name)
    end
  end
end
