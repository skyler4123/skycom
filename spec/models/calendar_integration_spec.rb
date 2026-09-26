require 'rails_helper'

RSpec.describe CalendarIntegration, type: :model do
  let(:company) { create(:company) }
  let(:user) { company.user }

  it "creates a valid integration with company scope" do
    integration = CalendarIntegration.new(
      company: company,
      accountable: user,
      provider: "cal_com",
      status: :active
    )
    expect(integration).to be_valid
  end

  it "requires a provider" do
    integration = CalendarIntegration.new(company: company, accountable: user, provider: nil)
    expect(integration).not_to be_valid
  end

  it "rejects duplicate provider per company + accountable" do
    CalendarIntegration.create!(company: company, accountable: user, provider: "cal_com")
    dup = CalendarIntegration.new(company: company, accountable: user, provider: "cal_com")
    expect(dup).not_to be_valid
  end

  it "exposes metadata accessors without extra jsonb columns" do
    integration = CalendarIntegration.new(
      company: company,
      accountable: user,
      calcom_event_type_id: "123",
      webhook_secret: "shh"
    )
    expect(integration.calcom_event_type_id).to eq("123")
    expect(integration.webhook_secret).to eq("shh")
  end
end
