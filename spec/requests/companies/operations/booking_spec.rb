# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Operations::BookingController", type: :request do
  let(:company) { create(:company, business_type: :education) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, timezone: :plus_7) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:facility_category) { Seed::CategoryService.create(company: company, name: "Office Space", resource_name: "facilities") }
  let(:room) do
    create(:facility, company: company, branch: branch, name: "Boardroom Orion", category: facility_category,
      property_mapping: facility_category.default_property_mapping)
  end
  let(:host) { create(:employee, company: company, branch: branch, name: "Marcus Sterling") }
  let(:customer) { create(:customer, company: company, name: "Vanguard Capital") }
  let(:date) { Date.new(2026, 11, 20) }
  let(:now) { Time.utc(2026, 11, 20, 3, 0, 0) }

  before { get sign_in_for_test_path(email: owner.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  def booking_event(name:, start_time:, end_time:, workflow_status: :confirmed)
    event = create(:event, company: company, branch: branch, category: event_category,
      name: name, start_at: LocalTime.parse(date, start_time, branch),
      end_at: LocalTime.parse(date, end_time, branch), workflow_status: workflow_status)
    EventFacilityAppointment.create!(company: company, event: event, facility: room)
    event
  end

  def post_json(path, params)
    post path, params: params.merge(branch_id: branch.id)
  end

  it "returns the server now, real counts and reference caps" do
    travel_to now do
      booking_event(name: "Current", start_time: "09:30", end_time: "10:30")

      get booking_company_operations_path(company, operation), params: { branch_id: branch.id }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("booking", "now")).to eq(now.iso8601)
      expect(body.dig("booking", "counts", "in_progress")).to eq(1)
      expect(body.dig("booking", "bookings", 0, "status")).to eq("in_progress")
      expect(body.dig("company", "name")).to eq(company.name)
      expect(body.dig("reference", "caps", "hosts")).to include("limit" => 100)
      expect(body.dig("reference", "facilities", 0)).to include("category" => "Office Space")
    end
  end

  it "creates a reservation with the selected host and customer" do
    post_json(booking_reservations_company_operations_path(company, operation),
      booking: {
        title: "Board review", facility_id: room.id, host_id: host.id,
        customer_id: customer.id, date: date.iso8601,
        start_time: "14:00", end_time: "15:00"
      })

    expect(response).to have_http_status(:created)
    event = Event.find_by!(company: company, name: "Board review")
    expect(event.employees).to contain_exactly(host)
    expect(event.customers).to contain_exactly(customer)
    expect(event.start_at).to eq(LocalTime.parse(date, "14:00", branch))
  end

  it "returns a named overlap error and creates nothing" do
    booking_event(name: "Existing", start_time: "11:50", end_time: "12:50")

    post_json(booking_reservations_company_operations_path(company, operation),
      booking: {
        title: "Second host", facility_id: room.id, date: date.iso8601,
        start_time: "12:00", end_time: "13:00"
      })

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["errors"]).to eq([ "Boardroom Orion is already booked 11:50 AM–12:50 PM." ])
    expect(Event.find_by(company: company, name: "Second host")).to be_nil
  end

  it "extends, ends and cancels a booking through the console endpoints" do
    event = booking_event(name: "Current", start_time: "09:30", end_time: "11:00")

    travel_to now do
      post_json(booking_reservation_extend_company_operations_path(company, operation, event.id), {})
      expect(response).to have_http_status(:ok)
      expect(event.reload.end_at).to eq(Time.utc(2026, 11, 20, 4, 30, 0))

      post_json(booking_reservation_end_company_operations_path(company, operation, event.id), {})
      expect(response).to have_http_status(:ok)
      expect(event.reload.workflow_status).to eq("completed")
      expect(event.end_at).to eq(now)

      other = booking_event(name: "Other", start_time: "14:00", end_time: "15:00")
      post_json(booking_reservation_cancel_company_operations_path(company, operation, other.id), {})
      expect(response).to have_http_status(:ok)
      expect(other.reload.workflow_status).to eq("cancelled")
    end
  end

  it "searches customers through Meilisearch" do
    allow(Customer).to receive(:ms_raw_search).and_return("hits" => [ { "id" => customer.id } ])

    get booking_customers_company_operations_path(company, operation),
      params: { branch_id: branch.id, q: "Vanguard" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["customers"]).to eq([
      { "id" => customer.id, "name" => "Vanguard Capital", "code" => customer.code, "email" => customer.email }
    ])
  end
end
