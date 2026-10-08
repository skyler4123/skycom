require "rails_helper"

RSpec.describe Companies::CompanyTicketsPolicy do
  let(:company) { create(:company) }
  let(:owner) { company.employees.find_by(business_type: "owner") }

  it "maps index/show to read and new/create to create" do
    policy = described_class.new(owner, owner)

    expect(policy.index?).to be(true)
    expect(policy.show?).to be(true)
    expect(policy.new?).to be(true)
    expect(policy.create?).to be(true)
  end

  it "maps rate to update" do
    policy = described_class.new(owner, owner)

    expect(policy.rate?).to be(true)
  end

  it "denies everything without grants" do
    stranger_company = create(:company)
    stranger = create(:employee, company: stranger_company)
    stranger_company.clear_permissions_cache
    stranger.clear_permissions_cache
    stranger.reload

    policy = described_class.new(stranger, stranger)

    expect(policy.index?).to be(false)
    expect(policy.create?).to be(false)
    expect(policy.rate?).to be(false)
  end
end
