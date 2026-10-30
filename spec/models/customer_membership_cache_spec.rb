# spec/models/customer_membership_cache_spec.rb
require "rails_helper"

RSpec.describe "Customer membership cache keys", type: :model do
  let(:company) { create(:company) }
  let(:customer) { create(:customer, company: company) }
  let(:membership) { create(:membership, company: company) }
  let!(:appointment) do
    create(:customer_membership_appointment, company: company, customer: customer, membership: membership)
  end

  it "caches the current membership under the service key in sync_cache" do
    expect(customer.membership).to eq(membership)

    expect(Rails.sync_cache.read(CacheKeyService.customer_current_membership(customer))).to eq(membership)
  end

  it "caches membership_of_type under the service key in sync_cache" do
    expect(customer.membership_of_type(:primary)).to eq(membership)

    expect(Rails.sync_cache.read(CacheKeyService.customer_membership_of_type(customer, :primary))).to eq(membership)
  end

  it "addresses a new key after the customer is touched" do
    customer.membership
    old_key = CacheKeyService.customer_current_membership(customer)

    customer.touch

    expect(CacheKeyService.customer_current_membership(customer)).not_to eq(old_key)
    expect(customer.reload.membership).to eq(membership)
  end
end
