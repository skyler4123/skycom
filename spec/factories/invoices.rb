# spec/factories/invoices.rb
FactoryBot.define do
  factory :invoice do
    association :order

    name { "Invoice for Order ##{order.id}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "INV-#{SecureRandom.hex(4).upcase}" }
    currency_code { Invoice.currency_codes.keys.sample }
    number { "INV-#{order.id}-#{SecureRandom.hex(4).upcase}" }
    total { Faker::Commerce.price }
    due_date { Faker::Date.forward(days: 30) }
    lifecycle_status { Invoice.lifecycle_statuses.keys.sample }
    workflow_status { Invoice.workflow_statuses.keys.sample }
    business_type { Invoice.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::InvoiceService.create(
        order: order,
        name: name,
        description: description,
        code: code,
        currency_code: currency_code,
        number: number,
        total: total,
        due_date: due_date,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

    skip_create
  end
end
