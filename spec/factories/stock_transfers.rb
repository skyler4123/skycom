# spec/factories/stock_transfers.rb
FactoryBot.define do
  factory :stock_transfer do
    association :company
    association :product

    initialize_with do
      Seed::StockTransferService.new(
        company: company,
        product: product,
        branch: nil,
        appoint_from: nil,
        appoint_to: nil
      )
    end
  end
end