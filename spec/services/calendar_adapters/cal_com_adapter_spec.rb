require 'rails_helper'

RSpec.describe CalendarAdapters::BaseAdapter, type: :service do
  let(:company) { create(:company) }
  let(:integration) do
    CalendarIntegration.create!(company: company, accountable: company.user, provider: "cal_com")
  end

  it "raises NotImplementedError for unimplemented methods" do
    adapter = described_class.new(integration)
    event = CalendarEvent.new(company: company, title: "x",
      starts_at: 1.day.from_now, ends_at: 1.day.from_now + 30.minutes)
    expect { adapter.create_event(event) }.to raise_error(NotImplementedError)
    expect { adapter.process_webhook({}) }.to raise_error(NotImplementedError)
  end
end

RSpec.describe CalendarAdapters::CalComAdapter, type: :service do
  let(:company) { create(:company) }
  let(:integration) do
    CalendarIntegration.create!(
      company: company, accountable: company.user, provider: "cal_com",
      status: :active, access_token: "tok",
      calcom_event_type_id: "42"
    )
  end
  let(:event) do
    CalendarEvent.create!(
      company: company, calendar_integration: integration,
      title: "ERP Setup Consultation",
      starts_at: 2.days.from_now, ends_at: 2.days.from_now + 45.minutes,
      attendees: [ { "name" => "Client", "email" => "client@example.com" } ]
    )
  end

  def stub_connection(response_success:, response_body:)
    response = double("response", success?: response_success, body: response_body)
    conn = double("conn")
    allow(conn).to receive(:post).and_return(response)
    allow_any_instance_of(described_class).to receive(:connection).and_return(conn)
    conn
  end

  it "creates a sync mapping when Cal.com accepts the booking" do
    stub_connection(
      response_success: true,
      response_body: { "data" => { "id" => 99, "uid" => "uid-99" } }
    )
    expect { described_class.new(integration).create_event(event) }.to change(CalendarSyncMapping, :count).by(1)
    mapping = CalendarSyncMapping.last
    expect(mapping.external_event_id).to eq("99")
    expect(mapping.external_booking_uid).to eq("uid-99")
    expect(mapping.company_id).to eq(company.id)
  end

  it "creates no mapping when Cal.com rejects the booking" do
    stub_connection(response_success: false, response_body: {})
    expect(described_class.new(integration).create_event(event)).to be(false)
    expect(CalendarSyncMapping.count).to eq(0)
  end

  it "imports a BOOKING_CREATED webhook into a confirmed event" do
    payload = {
      "triggerEvent" => "BOOKING_CREATED",
      "payload" => {
        "id" => 7, "uid" => "uid-7", "title" => "Meeting via Cal.com",
        "startTime" => 3.days.from_now.iso8601, "endTime" => (3.days.from_now + 30.minutes).iso8601,
        "attendees" => [ { "name" => "Alex", "email" => "alex@example.com" } ]
      }
    }
    expect { described_class.new(integration).process_webhook(payload) }.to change(CalendarEvent, :count).by(1)
    created = CalendarEvent.last
    expect(created.status).to eq("confirmed")
    expect(created.calendar_sync_mappings.first.external_event_id).to eq("7")
  end

  it "dedupes a repeated BOOKING_CREATED webhook" do
    payload = {
      "triggerEvent" => "BOOKING_CREATED",
      "payload" => {
        "id" => 7, "uid" => "uid-7", "title" => "Meeting",
        "startTime" => 3.days.from_now.iso8601, "endTime" => (3.days.from_now + 30.minutes).iso8601,
        "attendees" => []
      }
    }
    adapter = described_class.new(integration)
    adapter.process_webhook(payload)
    expect { adapter.process_webhook(payload) }.not_to change(CalendarEvent, :count)
  end

  it "cancels the local event on BOOKING_CANCELLED" do
    mapping = CalendarSyncMapping.create!(
      company: company, calendar_event: event, calendar_integration: integration,
      external_event_id: "11"
    )
    described_class.new(integration).process_webhook(
      "triggerEvent" => "BOOKING_CANCELLED", "payload" => { "id" => 11 }
    )
    expect(mapping.calendar_event.reload.status).to eq("cancelled")
  end

  it "reschedules the local event on BOOKING_RESCHEDULED" do
    mapping = CalendarSyncMapping.create!(
      company: company, calendar_event: event, calendar_integration: integration,
      external_event_id: "12"
    )
    new_start = 5.days.from_now
    described_class.new(integration).process_webhook(
      "triggerEvent" => "BOOKING_RESCHEDULED",
      "payload" => { "id" => 12, "startTime" => new_start.iso8601, "endTime" => (new_start + 30.minutes).iso8601 }
    )
    expect(mapping.calendar_event.reload.status).to eq("rescheduled")
    expect(mapping.reload.last_synced_at).to be_present
  end
end
