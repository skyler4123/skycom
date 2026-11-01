# spec/factories/kpi_configs.rb
FactoryBot.define do
  factory :kpi_config do
    association :company

    sequence(:name) { |n| "KPI #{n}" }
    metric_key { "orders_count" }
    direction { :higher_better }
    period_type { :month }
    target_value { 10 }
    weight { 1 }
    lifecycle_status { :active }
    workflow_status { :active }
    business_type { :performance }
  end
end
