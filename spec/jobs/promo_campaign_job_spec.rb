require "rails_helper"

RSpec.describe PromoCampaignJob, type: :job do
  it "executes a due campaign" do
    company = create(:company, :without_signup_promo)
    campaign = create(:promo_campaign, amount: 300, max_cap: 1000,
      conditions: {}, status: :scheduled, scheduled_at: 1.hour.ago)

    described_class.perform_now(campaign.id)

    expect(campaign.reload).to be_status_completed
    expect(company.company_wallet.reload.promo_credit_balance).to eq(300)
  end

  it "no-ops a completed campaign" do
    campaign = create(:promo_campaign, status: :completed, processed_at: Time.current)

    result = nil
    expect {
      described_class.perform_now(campaign.id)
    }.not_to raise_error
    expect(PromoGrant.where(promo_campaign: campaign).count).to eq(0)
  end
end
