# spec/factories/stock_pendings.rb
FactoryBot.define do
  factory :stock_pending do
    association :stock
    warehouse { stock.warehouse }
    product { stock.product }
    company { stock.company }
    quantity { 5 }
    workflow_status { :pending }
    business_type { :manual }
  end
end
