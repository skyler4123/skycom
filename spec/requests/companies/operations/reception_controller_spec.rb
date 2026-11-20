# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::Operations::ReceptionController", type: :request do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let!(:operation_record) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }

  before do
    get sign_in_for_test_path(email: user.email)
    @original_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
  end

  after { ActionController::Base.allow_forgery_protection = @original_forgery_protection }

  def create_visit(status: :confirmed, metadata: {})
    customer = create(:customer, company: company, name: "Jessica Tan", description: "Deloitte")
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Visit · Jessica Tan · #{SecureRandom.hex(2)}", start_at: Time.current,
      end_at: 1.hour.from_now, workflow_status: status,
      metadata: { "reception_kind" => "visit", "visitor_company" => "Deloitte" }.merge(metadata))
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host)
    event
  end

  it "returns the real reception payload" do
    visit_event = create_visit

    get reception_company_operations_path(company, operation_record, branch_id: branch.id, format: :json)

    expect(response).to have_http_status(:ok)
    payload = response.parsed_body
    expect(payload.dig("company", "name")).to eq(company.name)
    expect(payload.dig("reception", "visits").map { |row| row["id"] }).to include(visit_event.id)
    expect(payload.dig("reception", "counts")).to include("lobby" => 1, "expected" => 0)
    expect(payload.dig("reception", "generated_at")).to be_present
  end

  it "creates a walk-in visit with real fields" do
    post reception_check_in_company_operations_path(company, operation_record),
      params: { branch_id: branch.id, visitor: { name: "Jessica Tan", company: "Deloitte", host_id: host.id, vip: true } },
      as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["message"]).to eq("Walk-in check-in complete for Jessica Tan.")
    event = Event.find(response.parsed_body.dig("event", "id"))
    expect(event.workflow_status).to eq("confirmed")
    expect(event.metadata["reception_kind"]).to eq("visit")
    expect(event.metadata["vip"]).to be(true)
  end

  it "returns errors for an invalid walk-in" do
    post reception_check_in_company_operations_path(company, operation_record),
      params: { branch_id: branch.id, visitor: { name: "", company: "Deloitte" } },
      as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to contain_exactly("Guest name is required.")
  end

  it "pre-registers an expected visit" do
    post reception_pre_register_company_operations_path(company, operation_record),
      params: {
        branch_id: branch.id,
        pre_registration: {
          name: "Tomorrow Guest", company: "Acme", date: (Date.current + 1).to_s,
          start_time: "09:30", end_time: "10:00", host_id: host.id
        }
      },
      as: :json

    expect(response).to have_http_status(:created)
    event = Event.find(response.parsed_body.dig("event", "id"))
    expect(event.workflow_status).to eq("pending")
    expect(event.metadata["visitor_kind"]).to eq("Pre-registered")
  end

  it "moves a visit through advance and rejects an invalid transition" do
    event = create_visit(status: :pending)

    post reception_advance_company_operations_path(company, operation_record),
      params: { branch_id: branch.id, event_id: event.id, transition: "arrive" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(event.reload.workflow_status).to eq("confirmed")

    post reception_advance_company_operations_path(company, operation_record),
      params: { branch_id: branch.id, event_id: event.id, transition: "check_out" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to contain_exactly("This visit cannot be updated from its current state.")
  end

  it "notifies the host directly" do
    event = create_visit

    post reception_notify_host_company_operations_path(company, operation_record),
      params: { branch_id: branch.id, event_id: event.id }, as: :json

    expect(response).to have_http_status(:ok)
    expect(event.reload.metadata["host_notified_at"]).to be_present
    expect(Notification.find_by(recipient_employee: host)).to be_present
  end

  it "logs, notifies and picks up a parcel" do
    post reception_parcels_company_operations_path(company, operation_record),
      params: { branch_id: branch.id, parcel: { carrier: "DHL", item: "Legal documents", employee_id: host.id } },
      as: :json
    expect(response).to have_http_status(:created)
    parcel = Event.find(response.parsed_body.dig("event", "id"))
    expect(parcel.metadata).not_to have_key("locker")

    post reception_parcel_notify_company_operations_path(company, operation_record, parcel.id),
      params: { branch_id: branch.id }, as: :json
    expect(response).to have_http_status(:ok)
    expect(parcel.reload.workflow_status).to eq("received")
    expect(Notification.find_by(recipient_employee: host)).to be_present

    post reception_parcel_pick_up_company_operations_path(company, operation_record, parcel.id),
      params: { branch_id: branch.id }, as: :json
    expect(response).to have_http_status(:ok)
    expect(parcel.reload.workflow_status).to eq("completed")
  end

  it "does not serve another company's operation" do
    other_company = create(:company)
    other_branch = create(:branch, company: other_company)
    other_operation = create(:operation, company: other_company, branch: other_branch, operation_type: :reception)

    get reception_company_operations_path(other_company, other_operation, branch_id: other_branch.id, format: :json)

    expect(response).to have_http_status(:forbidden)
  end
end
