require 'rails_helper'

RSpec.describe CalendarSyncMapping, type: :model do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:integration) do
    CalendarIntegration.create!(company: company, accountable: user, provider: "cal_com")
  end
  let(:event) do
    CalendarEvent.create!(
      company: company, calendar_integration: integration,
      title: "Sync me", starts_at: 2.days.from_now, ends_at: 2.days.from_now + 30.minutes
    )
  end

  it "creates a valid mapping deriving company from the event" do
    mapping = CalendarSyncMapping.new(
      calendar_event: event,
      calendar_integration: integration,
      external_event_id: "ext-1"
    )
    expect(mapping).to be_valid
    mapping.save!
    expect(mapping.reload.company_id).to eq(company.id)
  end

  it "rejects duplicate external_event_id per integration" do
    CalendarSyncMapping.create!(
      company: company, calendar_event: event, calendar_integration: integration,
      external_event_id: "ext-1"
    )
    dup = CalendarSyncMapping.new(
      company: company, calendar_event: event, calendar_integration: integration,
      external_event_id: "ext-1"
    )
    expect(dup).not_to be_valid
  end
end
