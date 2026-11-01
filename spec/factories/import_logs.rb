# frozen_string_literal: true

FactoryBot.define do
  factory :import_log do
    import
    company { import.company }
    record { association :product, company: company }
    action { :created }
    source_row { 1 }
    record_type { record.class.name }
    record_id { record.id }
  end
end
