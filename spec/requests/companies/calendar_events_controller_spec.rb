# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CalendarEventsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:procedure) { create(:calendar_procedure, company: company) }
  let(:practitioner) { create(:calendar_practitioner, company: company) }
  let(:location) { create(:calendar_location, company: company) }

  let(:starts_at) { Time.current.change(sec: 0, usec: 0) }

  def booking_payload(overrides = {})
    {
      calendar_event: {
        calendar_procedure_id: procedure.id,
        title: "Tooth Extraction",
        starts_at: (starts_at + 1.day).iso8601,
        ends_at: (starts_at + 1.day + 60.minutes).iso8601,
        status: "confirmed"
      }.merge(overrides[:event] || {}),
      practitioner_ids: overrides.fetch(:practitioner_ids, [ practitioner.id ]),
      location_ids: overrides.fetch(:location_ids, [ location.id ])
    }.compact
  end

  # Request specs POST without a browser CSRF token — disable forgery for the
  # example (same pattern as stock_adjustments_spec / purchases_controller_spec).
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    get sign_in_for_test_path(email: owner.email)
  end

  describe "GET #index" do
    it "returns the company's bookings with their assignments" do
      event = create(:calendar_event, company: company, calendar_procedure: procedure)
      create(:calendar_event_practitioner, calendar_event: event, calendar_practitioner: practitioner, company: company)
      create(:calendar_event_location, calendar_event: event, calendar_location: location, company: company)

      get company_calendar_events_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["calendar_events"].size).to eq(1)
      expect(body["calendar_events"].first["display_title"]).to eq(event.display_title)
      expect(body["calendar_events"].first["practitioners"].first["name"]).to eq(practitioner.name)
      expect(body["calendar_events"].first["locations"].first["name"]).to eq(location.name)
      expect(body).to have_key("pagination")
      # The booking form's pickers ride along with the list.
      expect(body["options"]["procedures"].map { |p| p["id"] }).to include(procedure.id)
    end

    it "scopes to the current company" do
      other_company = create(:company)
      create(:calendar_event, company: other_company, title: "FOREIGNBOOKING")
      create(:calendar_event, company: company, title: "OURBOOKING")

      get company_calendar_events_path(company), as: :json

      titles = JSON.parse(response.body)["calendar_events"].map { |e| e["title"] }
      expect(titles).to include("OURBOOKING")
      expect(titles).not_to include("FOREIGNBOOKING")
    end

    it "excludes cancelled bookings" do
      create(:calendar_event, company: company, status: :cancelled)

      get company_calendar_events_path(company, status: "pending"), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      create(:calendar_event, company: company, status: :confirmed)
      create(:calendar_event, company: company, status: :cancelled)

      get company_calendar_events_path(company, status: "cancelled"), as: :json

      statuses = JSON.parse(response.body)["calendar_events"].map { |e| e["status"] }
      expect(statuses).to eq([ "cancelled" ])
    end

    it "finds a booking by participant name via ?q=" do
      event = create(:calendar_event, company: company)
      participant = create(:calendar_participant, company: company, name: "Zaphod Beeblebrox")
      create(:calendar_event_participant, calendar_event: event, calendar_participant: participant, company: company)

      get company_calendar_events_path(company, q: "Zaphod"), as: :json

      expect(JSON.parse(response.body)["calendar_events"].map { |e| e["id"] }).to eq([ event.id ])
    end
  end

  describe "POST #create" do
    it "books the appointment with its assignments" do
      post company_calendar_events_path(company), params: booking_payload, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Appointment booked successfully!")
      expect(body["calendar_event"]["practitioners"].first["role"]).to eq("lead")
      expect(body["calendar_event"]["locations"].first["role"]).to eq("primary")
    end

    it "rejects a double-booked practitioner with errors (plural array)" do
      existing = create(:calendar_event, company: company, calendar_procedure: procedure,
        starts_at: starts_at + 1.day, ends_at: starts_at + 1.day + 60.minutes)
      create(:calendar_event_practitioner, calendar_event: existing, calendar_practitioner: practitioner,
        company: company, role: "lead")

      post company_calendar_events_path(company), params: booking_payload, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_an(Array)
      expect(body["errors"].join).to include("already booked")
    end

    it "rejects a double-booked location even with a different practitioner" do
      existing = create(:calendar_event, company: company, calendar_procedure: procedure,
        starts_at: starts_at + 1.day, ends_at: starts_at + 1.day + 60.minutes)
      create(:calendar_event_location, calendar_event: existing, calendar_location: location, company: company)

      other_practitioner = create(:calendar_practitioner, company: company)
      post company_calendar_events_path(company),
        params: booking_payload(practitioner_ids: [ other_practitioner.id ]), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("already booked")
    end

    it "allows a back-to-back booking for the same practitioner" do
      existing = create(:calendar_event, company: company, calendar_procedure: procedure,
        starts_at: starts_at + 1.day, ends_at: starts_at + 1.day + 60.minutes)
      create(:calendar_event_practitioner, calendar_event: existing, calendar_practitioner: practitioner, company: company)

      post company_calendar_events_path(company), params: booking_payload(
        event: {
          starts_at: (starts_at + 1.day + 60.minutes).iso8601,
          ends_at: (starts_at + 1.day + 120.minutes).iso8601
        }
      ), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "rejects an end time before the start time" do
      post company_calendar_events_path(company), params: booking_payload(
        event: { ends_at: (starts_at + 1.day - 60.minutes).iso8601 }
      ), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("after the start")
    end

    it "rejects a procedure from another company" do
      foreign = create(:calendar_procedure, company: create(:company))

      post company_calendar_events_path(company),
        params: booking_payload(event: { calendar_procedure_id: foreign.id }), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST #conflicts" do
    it "previews a clash without writing anything" do
      existing = create(:calendar_event, company: company, calendar_procedure: procedure,
        starts_at: starts_at + 1.day, ends_at: starts_at + 1.day + 60.minutes)
      create(:calendar_event_practitioner, calendar_event: existing, calendar_practitioner: practitioner, company: company)

      expect {
        post conflicts_company_calendar_events_path(company), params: booking_payload, as: :json
      }.not_to change(CalendarEvent, :count)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["conflicts"]).to be_present
    end

    it "reports no conflict for a free slot" do
      post conflicts_company_calendar_events_path(company), params: booking_payload, as: :json

      expect(JSON.parse(response.body)["conflicts"]).to eq([])
    end
  end

  describe "status transitions" do
    let!(:event) { create(:calendar_event, company: company, calendar_procedure: procedure, status: :pending) }

    it "confirms a pending booking" do
      post confirm_company_calendar_event_path(company, event), as: :json

      expect(response).to have_http_status(:ok)
      expect(event.reload.status).to eq("confirmed")
      expect(event.confirmed_at).to be_present
    end

    it "cancels and stamps the reason" do
      post cancel_company_calendar_event_path(company, event), params: { reason: "Patient rescheduled" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(event.reload.status).to eq("cancelled")
      expect(event.cancellation_reason).to eq("Patient rescheduled")
    end

    it "frees the room once cancelled" do
      create(:calendar_event_location, calendar_event: event, calendar_location: location, company: company)
      post cancel_company_calendar_event_path(company, event), as: :json

      post company_calendar_events_path(company), params: booking_payload, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "completes a booking" do
      post complete_company_calendar_event_path(company, event), as: :json

      expect(event.reload.status).to eq("completed")
    end
  end

  describe "GET #show / #edit / #new" do
    it "renders the shells and JSON" do
      event = create(:calendar_event, company: company, calendar_procedure: procedure)

      get company_calendar_event_path(company, event), as: :json
      expect(response).to have_http_status(:ok)

      get edit_company_calendar_event_path(company, event), as: :json
      expect(JSON.parse(response.body)).to have_key("options")

      get new_company_calendar_event_path(company), as: :json
      expect(JSON.parse(response.body)["calendar_event"]).to have_key("status")
    end
  end

  describe "DELETE #destroy" do
    it "removes the booking and its assignments" do
      event = create(:calendar_event, company: company, calendar_procedure: procedure)
      create(:calendar_event_practitioner, calendar_event: event, calendar_practitioner: practitioner, company: company)

      expect { delete company_calendar_event_path(company, event), as: :json }
        .to change(CalendarEvent, :count).by(-1)

      expect(CalendarEventPractitioner.where(calendar_event_id: event.id)).to be_empty
    end
  end

  describe "tenancy" do
    it "cannot show another company's booking" do
      foreign = create(:calendar_event, company: create(:company))

      get company_calendar_event_path(company, foreign), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
