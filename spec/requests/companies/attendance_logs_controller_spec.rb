# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::AttendanceLogsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:alice) { create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") } }
  let(:bob) { create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") } }

  let!(:alice_log) do
    AttendanceLog.create!(company: company, employee: alice, log_type: :check_in, logged_at: Time.zone.parse("2026-09-10 09:00"))
  end
  let!(:bob_log) do
    AttendanceLog.create!(company: company, employee: bob, log_type: :check_out, logged_at: Time.zone.parse("2026-09-12 18:00"))
  end

  before { get sign_in_for_test_path(email: owner_user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def log_ids(body)
    JSON.parse(body)["attendance_logs"].map { |l| l["id"] }
  end

  it "filters by employee_name (partial, case-insensitive)" do
    get company_attendance_logs_path(company, format: :json), params: { employee_name: "alice" }
    ids = log_ids(response.body)
    expect(ids).to include(alice_log.id)
    expect(ids).not_to include(bob_log.id)
  end

  it "filters by log_type" do
    get company_attendance_logs_path(company, format: :json), params: { log_type: "check_out" }
    ids = log_ids(response.body)
    expect(ids).to include(bob_log.id)
    expect(ids).not_to include(alice_log.id)
  end

  it "filters by from/to range on logged_at" do
    get company_attendance_logs_path(company, format: :json), params: { from: "2026-09-11", to: "2026-09-13" }
    ids = log_ids(response.body)
    expect(ids).to include(bob_log.id)
    expect(ids).not_to include(alice_log.id)
  end

  it "ignores bogus filter params instead of 500ing" do
    get company_attendance_logs_path(company, format: :json), params: { log_type: "hijack", from: "not-a-date", to: "%%%" }
    expect(response).to have_http_status(:ok)
    expect(log_ids(response.body)).to include(alice_log.id, bob_log.id)
  end

  it "scopes to the company" do
    other = create(:company)
    other_employee = create(:employee, company: other).tap { |e| e.update!(name: "Alice Clone") }
    foreign = AttendanceLog.create!(company: other, employee: other_employee, log_type: :check_in, logged_at: Time.zone.parse("2026-09-10 09:00"))
    get company_attendance_logs_path(company, format: :json), params: { employee_name: "alice" }
    expect(log_ids(response.body)).not_to include(foreign.id)
  end
end
