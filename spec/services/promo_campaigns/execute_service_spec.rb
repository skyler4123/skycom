require "rails_helper"

RSpec.describe PromoCampaigns::ExecuteService, type: :model do
  let!(:company) do
    c = create(:company)
    c.update!(business_type: :retail, country: :us, employee_count: 50)
    c
  end

  def campaign_for(amount:, max_cap:, conditions: {})
    create(:promo_campaign, amount: amount, max_cap: max_cap,
      conditions: conditions, status: :scheduled, scheduled_at: 1.hour.ago)
  end

  it "grants full amount and notifies the owner" do
    company.company_wallet.add_to!(balance: :promo, amount: 600)
    campaign = campaign_for(amount: 300, max_cap: 1000)

    result = described_class.call(campaign: campaign)

    expect(result[:success]).to be true
    expect(result[:granted]).to eq(1)
    expect(company.company_wallet.reload.promo_credit_balance).to eq(900)
    grant = PromoGrant.find_by(promo_campaign: campaign, company: company)
    expect(grant.granted_amount).to eq(300)
    expect(grant.promo_before).to eq(600)
    expect(grant.promo_after).to eq(900)
    expect(CompanyWalletLog.where(company: company, balance_type: :promo).count).to be >= 1
    owner = company.employees.find_by(business_type: :owner)
    tag_ids = EmployeeNotificationTagAppointment.where(company: company, employee: owner).pluck(:notification_tag_id)
    expect(Notification.joins(:notification_tag_appointments)
      .where(company: company, notification_tag_appointments: { notification_tag_id: tag_ids }).count).to be >= 1
  end

  it "notifies with campaign title/body" do
    campaign = campaign_for(amount: 300, max_cap: 1000)
    campaign.update!(title: "Custom title 300", body: "Custom body cap 1000")

    described_class.call(campaign: campaign)

    n = Notification.where(company: company).order(created_at: :desc).first
    expect(n.name).to eq("Custom title 300")
    expect(n.description).to eq("Custom body cap 1000")
  end

  it "falls back to defaults when title/body blank (legacy)" do
    campaign = campaign_for(amount: 300, max_cap: 1000)
    campaign.update_columns(title: "", body: "")

    described_class.call(campaign: campaign.reload)

    n = Notification.where(company: company).order(created_at: :desc).first
    expect(n.name).to include("300")
    expect(n.description).to include(campaign.name)
  end

  it "grants partial amount at the cap (900 + 300 cap 1000 → +100)" do
    company.company_wallet.add_to!(balance: :promo, amount: 900)
    campaign = campaign_for(amount: 300, max_cap: 1000)

    result = described_class.call(campaign: campaign)

    expect(result[:success]).to be true
    expect(company.company_wallet.reload.promo_credit_balance).to eq(1000)
    expect(PromoGrant.find_by(promo_campaign: campaign, company: company).granted_amount).to eq(100)
  end

  it "skips companies already at cap (1100 + 300 cap 1000)" do
    company.company_wallet.add_to!(balance: :promo, amount: 1100)
    campaign = campaign_for(amount: 300, max_cap: 1000)

    result = described_class.call(campaign: campaign)

    expect(result[:success]).to be true
    expect(result[:skipped]).to eq(1)
    expect(company.company_wallet.reload.promo_credit_balance).to eq(1100)
    expect(PromoGrant.where(promo_campaign: campaign, company: company).count).to eq(0)
    expect(Notification.where(company: company).count).to eq(0)
  end

  it "leaves non-matching companies untouched with no notification" do
    other = create(:company)
    other.update!(business_type: :retail, country: :vn, employee_count: 50)
    company.update!(country: :us)
    campaign = campaign_for(amount: 300, max_cap: 1000, conditions: { "country" => [ "us" ] })

    described_class.call(campaign: campaign)

    expect(other.company_wallet.reload.promo_credit_balance).to eq(0)
    expect(Notification.where(company: other).count).to eq(0)
  end

  it "is idempotent on re-run" do
    campaign = campaign_for(amount: 300, max_cap: 1000)
    described_class.call(campaign: campaign)

    again = described_class.call(campaign: campaign.reload)

    expect(again[:success]).to be false
    expect(PromoGrant.where(promo_campaign: campaign).count).to eq(1)
  end

  it "grants without notification when owner is missing" do
    owner = company.employees.find_by(business_type: :owner)
    EmployeeRoleAppointment.where(employee_id: owner.id).delete_all
    owner.delete
    campaign = campaign_for(amount: 300, max_cap: 1000)

    result = described_class.call(campaign: campaign)

    expect(result[:success]).to be true
    expect(result[:granted]).to eq(1)
    expect(company.company_wallet.reload.promo_credit_balance).to eq(300)
    expect(Notification.where(company: company).count).to eq(0)
  end

  it "still grants when notification fails" do
    allow(Notifications::CreateService).to receive(:call).and_raise("WS down")
    campaign = campaign_for(amount: 300, max_cap: 1000)

    result = described_class.call(campaign: campaign)

    expect(result[:success]).to be true
    expect(result[:granted]).to eq(1)
    expect(result[:failed]).to eq(0)
    expect(company.company_wallet.reload.promo_credit_balance).to eq(300)
    expect(PromoGrant.where(promo_campaign: campaign).count).to eq(1)
  end
end
