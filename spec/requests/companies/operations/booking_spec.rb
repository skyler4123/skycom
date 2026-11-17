# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Operations::BookingController", type: :request do
  let(:company) { create(:company, business_type: :education) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, timezone: :plus_7) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }

  before { get sign_in_for_test_path(email: owner.email) }

  it "returns ISO booking timestamps with the location timezone" do
    travel_to Time.utc(2026, 11, 17, 2, 0, 0) do
      event = create(:event, company: company, branch: branch, category: event_category,
        name: "Local Time Review", code: "BKG-LOCAL",
        start_at: Time.utc(2026, 11, 17, 2, 0, 0), end_at: Time.utc(2026, 11, 17, 3, 0, 0),
        workflow_status: :confirmed)

      get booking_company_operations_path(company, operation), params: { branch_id: branch.id }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      booking = body.dig("booking", "bookings").find { |row| row["id"] == event.id }

      expect(booking["title"]).to eq("Local Time Review")
      expect(booking["start_at"]).to eq("2026-11-17T02:00:00Z")
      expect(booking).not_to have_key("start_label")
      expect(body.dig("appointment", "location", "timezone")).to eq("plus_7")
      expect(body.dig("appointment", "location", "utc_offset")).to eq(25_200)
      expect(body.dig("booking", "date")).to eq("2026-11-17")
    end
  end
end
