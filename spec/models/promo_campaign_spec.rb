require "rails_helper"

RSpec.describe PromoCampaign, type: :model do
  it "rejects non-positive amount" do
    c = build(:promo_campaign, amount: 0)
    expect(c).not_to be_valid
    expect(c.errors[:amount]).to be_present
  end

  it "rejects non-positive max_cap" do
    c = build(:promo_campaign, max_cap: -1)
    expect(c).not_to be_valid
    expect(c.errors[:max_cap]).to be_present
  end

  it "rejects unknown condition key" do
    c = build(:promo_campaign, conditions: { "foo" => 1 })
    expect(c).not_to be_valid
    expect(c.errors[:conditions]).to be_present
  end

  it "rejects min > max in conditions" do
    c = build(:promo_campaign, conditions: { "employee_count_min" => 10, "employee_count_max" => 5 })
    expect(c).not_to be_valid
    expect(c.errors[:conditions]).to be_present
  end

  it "rejects unknown country value" do
    c = build(:promo_campaign, conditions: { "country" => [ "xx" ] })
    expect(c).not_to be_valid
    expect(c.errors[:conditions]).to be_present
  end

  it "accepts empty conditions (matches all non-system)" do
    c = build(:promo_campaign, conditions: {})
    expect(c).to be_valid
  end

  it "accepts a full valid conditions hash" do
    c = build(:promo_campaign, conditions: {
      "country" => [ "us" ],
      "business_type" => [ "retail" ],
      "employee_count_min" => 5,
      "employee_count_max" => 100,
      "promo_balance_min" => 0,
      "promo_balance_max" => 500
    })
    expect(c).to be_valid
  end
end
