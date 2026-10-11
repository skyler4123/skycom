# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::AttendanceDaysController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:alice) { create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") } }
  let(:bob) { create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") } }

  let!(:alice_day) do
    AttendanceDay.create!(company: company, employee: alice, attendance_date: Date.parse("2026-09-10"), attendance_status: :present, total_seconds_worked: 28_800)
  end
  let!(:bob_day) do
    AttendanceDay.create!(company: company, employee: bob, attendance_date: Date.parse("2026-09-12"), attendance_status: :late, total_seconds_worked: 27_000)
  end

  before { get sign_in_for_test_path(email: owner_user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def day_ids(body)
    JSON.parse(body)["attendance_days"].map { |d| d["id"] }
  end

  it "filters by employee_name (partial, case-insensitive)" do
    get company_attendance_days_path(company, format: :json), params: { employee_name: "BOB" }
    ids = day_ids(response.body)
    expect(ids).to include(bob_day.id)
    expect(ids).not_to include(alice_day.id)
  end

  it "filters by attendance_status" do
    get company_attendance_days_path(company, format: :json), params: { attendance_status: "late" }
    ids = day_ids(response.body)
    expect(ids).to include(bob_day.id)
    expect(ids).not_to include(alice_day.id)
  end

  it "filters by from/to range on attendance_date" do
    get company_attendance_days_path(company, format: :json), params: { from: "2026-09-11", to: "2026-09-13" }
    ids = day_ids(response.body)
    expect(ids).to include(bob_day.id)
    expect(ids).not_to include(alice_day.id)
  end

  it "ignores bogus filter params instead of 500ing" do
    get company_attendance_days_path(company, format: :json), params: { attendance_status: "hijack", from: "not-a-date", to: "%%%" }
    expect(response).to have_http_status(:ok)
    expect(day_ids(response.body)).to include(alice_day.id, bob_day.id)
  end

  it "scopes to the company" do
    other = create(:company)
    other_employee = create(:employee, company: other).tap { |e| e.update!(name: "Alice Clone") }
    foreign = AttendanceDay.create!(company: other, employee: other_employee, attendance_date: Date.parse("2026-09-10"), attendance_status: :present, total_seconds_worked: 28_800)
    get company_attendance_days_path(company, format: :json), params: { employee_name: "alice" }
    expect(day_ids(response.body)).not_to include(foreign.id)
  end
end
