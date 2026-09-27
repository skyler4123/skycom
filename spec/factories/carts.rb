# spec/factories/carts.rb
FactoryBot.define do
  factory :cart do
    association :company
    branch { association :branch, company: company }
    cart_group { association :cart_group, company: company, branch: branch }
    name { "Cart #{SecureRandom.hex(4)}" }

    # NOTE: Seed::CartService.new does not accept company/cart_group and
    # Cart requires both, so the factory builds the record directly.
    # Category + property_mapping resolve at save via concerns.
    initialize_with do
      Cart.new(
        company: company,
        branch: branch,
        cart_group: cart_group,
        name: name,
        business_type: :shopping
      )
    end
  end
end
