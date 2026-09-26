require 'rails_helper'

RSpec.describe "Webhooks::Calendar::CalCom", type: :request do
  include ActiveJob::TestHelper

  before { ActiveJob::Base.queue_adapter = :test }
  after { ActiveJob::Base.queue_adapter = :async }

  let(:company) { create(:company) }
  let!(:integration) do
    CalendarIntegration.create!(
      company: company, accountable: company.user,
      provider: "cal_com", status: :active, access_token: "tok"
    )
  end

  def sign(body)
    OpenSSL::HMAC.hexdigest("SHA256", CALCOM_WEBHOOK_SECRET, body)
  end

  it "accepts a signed webhook, enqueues the sync job, returns ok" do
    body = {
      triggerEvent: "BOOKING_CREATED",
      payload: {
        id: 7, uid: "uid-7", title: "Meeting",
        startTime: 3.days.from_now.iso8601, endTime: (3.days.from_now + 30.minutes).iso8601,
        attendees: []
      }
    }.to_json
    expect {
      post "/webhooks/calendar/cal_com",
        params: body,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Cal-Signature-256" => sign(body)
        }
    }.to have_enqueued_job(CalendarSyncJob)
    expect(response).to have_http_status(:ok)
  end

  it "rejects an unsigned webhook with 401 and enqueues nothing" do
    expect {
      post "/webhooks/calendar/cal_com",
        params: { triggerEvent: "BOOKING_CREATED" }.to_json,
        headers: { "CONTENT_TYPE" => "application/json", "X-Cal-Signature-256" => "bad" }
    }.not_to have_enqueued_job(CalendarSyncJob)
    expect(response).to have_http_status(:unauthorized)
  end
end

RSpec.describe CalendarSyncJob, type: :job do
  let(:company) { create(:company) }
  let!(:integration) do
    CalendarIntegration.create!(
      company: company, accountable: company.user,
      provider: "cal_com", status: :active, access_token: "tok"
    )
  end

  it "imports BOOKING_CREATED into the integration company" do
    payload = {
      "triggerEvent" => "BOOKING_CREATED",
      "payload" => {
        "id" => 21, "uid" => "uid-21", "title" => "Job import",
        "startTime" => 3.days.from_now.iso8601, "endTime" => (3.days.from_now + 30.minutes).iso8601,
        "attendees" => []
      }
    }
    expect {
      described_class.perform_now(company_id: company.id, payload: payload)
    }.to change { company.calendar_events.count }.by(1)
    expect(company.calendar_events.last.status).to eq("confirmed")
  end
end
