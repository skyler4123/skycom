require "rails_helper"

RSpec.describe PromoCampaigns::MatcherService, type: :model do
  let!(:retail_us) do
    c = create(:company)
    c.update!(business_type: :retail, country: :us, employee_count: 50)
    c
  end
  let!(:retail_vn) do
    c = create(:company)
    c.update!(business_type: :retail, country: :vn, employee_count: 50)
    c
  end

  it "matches by country" do
    campaign = create(:promo_campaign, conditions: { "country" => [ "us" ] })
    ids = described_class.call(campaign: campaign).pluck(:id)
    expect(ids).to include(retail_us.id)
    expect(ids).not_to include(retail_vn.id)
  end

  it "matches by promo balance range" do
    retail_us.company_wallet.add_to!(balance: :promo, amount: 100)
    retail_vn.company_wallet.add_to!(balance: :promo, amount: 900)
    campaign = create(:promo_campaign, conditions: { "promo_balance_max" => 500 })
    ids = described_class.call(campaign: campaign).pluck(:id)
    expect(ids).to include(retail_us.id)
    expect(ids).not_to include(retail_vn.id)
  end

  it "excludes system companies even with empty conditions" do
    system_company = create(:company)
    system_company.update!(business_type: :system)
    campaign = create(:promo_campaign, conditions: {})
    ids = described_class.call(campaign: campaign).pluck(:id)
    expect(ids).not_to include(system_company.id)
  end

  it "matches by business_type and employee_count range" do
    campaign = create(:promo_campaign, conditions: {
      "business_type" => [ "retail" ],
      "employee_count_min" => 10,
      "employee_count_max" => 100
    })
    ids = described_class.call(campaign: campaign).pluck(:id)
    expect(ids).to include(retail_us.id, retail_vn.id)
  end
end
