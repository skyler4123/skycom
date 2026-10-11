# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::AttendanceMonthsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:alice) { create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") } }
  let(:bob) { create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") } }

  let!(:alice_month) do
    AttendanceMonth.create!(company: company, employee: alice, month: Date.parse("2026-08-01"), total_absent_days: 0, total_deficit_minutes: 0, total_present_days: 22)
  end
  let!(:bob_month) do
    AttendanceMonth.create!(company: company, employee: bob, month: Date.parse("2026-09-01"), total_absent_days: 5, total_deficit_minutes: 300, total_present_days: 17)
  end

  before { get sign_in_for_test_path(email: owner_user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def month_ids(body)
    JSON.parse(body)["attendance_months"].map { |m| m["id"] }
  end

  it "filters by employee_name (partial, case-insensitive)" do
    get company_attendance_months_path(company, format: :json), params: { employee_name: "alice" }
    ids = month_ids(response.body)
    expect(ids).to include(alice_month.id)
    expect(ids).not_to include(bob_month.id)
  end

  it "filters by from/to range on month" do
    get company_attendance_months_path(company, format: :json), params: { from: "2026-09-01", to: "2026-09-30" }
    ids = month_ids(response.body)
    expect(ids).to include(bob_month.id)
    expect(ids).not_to include(alice_month.id)
  end

  it "filters by min_absent_days" do
    get company_attendance_months_path(company, format: :json), params: { min_absent_days: "3" }
    ids = month_ids(response.body)
    expect(ids).to include(bob_month.id)
    expect(ids).not_to include(alice_month.id)
  end

  it "filters by min_deficit_minutes" do
    get company_attendance_months_path(company, format: :json), params: { min_deficit_minutes: "100" }
    ids = month_ids(response.body)
    expect(ids).to include(bob_month.id)
    expect(ids).not_to include(alice_month.id)
  end

  it "ignores bogus filter params instead of 500ing" do
    get company_attendance_months_path(company, format: :json), params: { from: "not-a-date", to: "%%%", min_absent_days: "abc", min_deficit_minutes: "xyz" }
    expect(response).to have_http_status(:ok)
    expect(month_ids(response.body)).to include(alice_month.id, bob_month.id)
  end

  it "scopes to the company" do
    other = create(:company)
    other_employee = create(:employee, company: other).tap { |e| e.update!(name: "Alice Clone") }
    foreign = AttendanceMonth.create!(company: other, employee: other_employee, month: Date.parse("2026-08-01"), total_absent_days: 0, total_deficit_minutes: 0)
    get company_attendance_months_path(company, format: :json), params: { employee_name: "alice" }
    expect(month_ids(response.body)).not_to include(foreign.id)
  end
end
