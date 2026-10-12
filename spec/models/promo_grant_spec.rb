require "rails_helper"

RSpec.describe PromoGrant, type: :model do
  it "requires a positive granted_amount" do
    g = build(:promo_grant, granted_amount: 0)
    expect(g).not_to be_valid
    expect(g.errors[:granted_amount]).to be_present
  end

  it "is valid with campaign, company and snapshots" do
    g = build(:promo_grant)
    expect(g).to be_valid
  end
end
