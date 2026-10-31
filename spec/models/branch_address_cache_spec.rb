# spec/models/branch_address_cache_spec.rb
require "rails_helper"

RSpec.describe "Address cache keys", type: :model do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:address) { create(:address) }
  let!(:appointment) do
    create(:address_branch_appointment, address: address, branch: branch)
  end

  it "caches the current address under the service key in sync_cache" do
    expect(branch.address).to eq(address)

    expect(Rails.sync_cache.read(CacheKeyService.current_address(branch))).to eq(address)
  end

  it "addresses a new key after the owner is touched" do
    branch.address
    old_key = CacheKeyService.current_address(branch)

    branch.touch

    expect(CacheKeyService.current_address(branch)).not_to eq(old_key)
    expect(branch.reload.address).to eq(address)
  end
end
