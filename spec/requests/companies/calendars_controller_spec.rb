# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CalendarsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:procedure) { create(:calendar_procedure, company: company) }

  # Request specs POST/PATCH without a browser CSRF token.
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: owner.email) }

  def event_at(offset_hours, duration: 60, status: :confirmed, co: company)
    starts = Time.current.change(sec: 0, usec: 0) + offset_hours.hours
    create(:calendar_event, company: co, calendar_procedure: procedure,
      starts_at: starts, ends_at: starts + duration.minutes, status: status)
  end

  describe "GET #index" do
    it "renders the board shell" do
      get company_calendars_path(company)

      expect(response).to have_http_status(:ok)
    end

    it "returns board metadata as JSON" do
      event_at(1)
      get company_calendars_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["calendar"]).to have_key("today")
      expect(body["calendar"]["events"]).to eq(1)
    end
  end

  describe "GET #events" do
    it "returns events inside the requested window" do
      inside = event_at(2)
      event_at(48) # far outside a 24h window

      get events_company_calendars_path(company, start: 1.hour.ago.iso8601, end: 6.hours.from_now.iso8601), as: :json

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["events"].map { |e| e["id"] }
      expect(ids).to eq([ inside.id ])
    end

    it "excludes cancelled events so a freed slot shows as bookable" do
      event_at(2, status: :cancelled)

      get events_company_calendars_path(company, start: 1.hour.ago.iso8601, end: 6.hours.from_now.iso8601), as: :json

      expect(JSON.parse(response.body)["events"]).to be_empty
    end

    it "includes no_show and completed events (they still happened)" do
      done = event_at(2, status: :completed)
      missed = event_at(3, status: :no_show)

      get events_company_calendars_path(company, start: 1.hour.ago.iso8601, end: 6.hours.from_now.iso8601), as: :json

      ids = JSON.parse(response.body)["events"].map { |e| e["id"] }
      expect(ids).to match_array([ done.id, missed.id ])
    end

    it "scopes to the current company" do
      other = create(:company)
      mine = event_at(2)
      # The event must carry its own company's procedure (cross-company
      # procedure is rejected by CalendarEvent validation).
      foreign_procedure = create(:calendar_procedure, company: other)
      create(:calendar_event, company: other, calendar_procedure: foreign_procedure,
        starts_at: 2.hours.from_now, ends_at: 3.hours.from_now)

      get events_company_calendars_path(company, start: 1.hour.ago.iso8601, end: 6.hours.from_now.iso8601), as: :json

      ids = JSON.parse(response.body)["events"].map { |e| e["id"] }
      expect(ids).to eq([ mine.id ])
    end

    it "returns the widget's expected field names" do
      practitioner = create(:calendar_practitioner, company: company)
      location = create(:calendar_location, company: company)
      event = event_at(2)
      create(:calendar_event_practitioner, calendar_event: event, calendar_practitioner: practitioner, company: company)
      create(:calendar_event_location, calendar_event: event, calendar_location: location, company: company)

      get events_company_calendars_path(company, start: 1.hour.ago.iso8601, end: 6.hours.from_now.iso8601), as: :json

      payload = JSON.parse(response.body)["events"].first
      expect(payload.keys).to include("id", "title", "start", "end", "allDay", "backgroundColor", "extendedProps")
      expect(payload["extendedProps"]["practitioners"]).to eq([ practitioner.name ])
      expect(payload["extendedProps"]["location_name"]).to eq(location.name)
    end

    it "includes an event late on the final day of the requested window" do
      # Regression: the grid asks with plain YYYY-MM-DD, so the range end must
      # cover the whole day. Midnight would drop the entire final day.
      late = create(:calendar_event, company: company, calendar_procedure: procedure,
        starts_at: Time.current.end_of_day - 30.minutes,
        ends_at: Time.current.end_of_day)

      day = late.starts_at.to_date
      get events_company_calendars_path(company, start: day.iso8601, end: day.iso8601), as: :json

      expect(JSON.parse(response.body)["events"].map { |e| e["id"] }).to eq([ late.id ])
    end

    it "includes an event late on the last day of a month window" do
      last_day = Date.current.end_of_month
      late = create(:calendar_event, company: company, calendar_procedure: procedure,
        starts_at: last_day.in_time_zone.change(hour: 15, min: 0),
        ends_at: last_day.in_time_zone.change(hour: 16, min: 0))

      get events_company_calendars_path(company,
        start: Date.current.beginning_of_month.iso8601, end: last_day.iso8601), as: :json

      expect(JSON.parse(response.body)["events"].map { |e| e["id"] }).to include(late.id)
    end

    it "falls back to a sane window when start/end are missing" do
      event_at(2)

      get events_company_calendars_path(company), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["events"]).to be_present
    end

    it "ignores an unparseable range instead of erroring" do
      get events_company_calendars_path(company, start: "not-a-date", end: "nope"), as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  describe "tenancy" do
    it "returns nothing for a company with no bookings" do
      create(:calendar_event, company: create(:company))

      get events_company_calendars_path(company, start: 1.hour.ago.iso8601, end: 6.hours.from_now.iso8601), as: :json

      expect(JSON.parse(response.body)["events"]).to be_empty
    end
  end
end
