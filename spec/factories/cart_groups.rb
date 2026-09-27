# spec/factories/cart_groups.rb
FactoryBot.define do
  factory :cart_group do
    association :company
    branch { association :branch, company: company }
    name { "Cart Group #{SecureRandom.hex(4)}" }
    code { "CG-#{SecureRandom.hex(4).upcase}" }

    # NOTE: Seed::CartGroupService.create does not accept a company and
    # CartGroup requires one, so the factory builds the record directly.
    # Category + property_mapping resolve at save via concerns.
    initialize_with do
      CartGroup.new(
        company: company,
        branch: branch,
        name: name,
        code: code,
        business_type: :active_carts
      )
    end
  end
end
