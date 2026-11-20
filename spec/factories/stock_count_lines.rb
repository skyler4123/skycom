# spec/factories/stock_count_lines.rb
FactoryBot.define do
  factory :stock_count_line do
    stock_count
    stock

    company { stock.company }
    expected_quantity { stock.quantity }
  end
end
