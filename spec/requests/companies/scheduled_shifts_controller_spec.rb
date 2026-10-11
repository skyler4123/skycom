# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::ScheduledShiftsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:branch) { company.branches.first || create(:branch, company: company) }
  let(:alice) { create(:employee, company: company).tap { |e| e.update!(name: "Alice Wonderland") } }
  let(:bob) { create(:employee, company: company).tap { |e| e.update!(name: "Bob Builder") } }

  let!(:alice_shift) do
    ScheduledShift.create!(company: company, branch: branch, employee: alice, work_date: Date.parse("2026-09-10"),
      expected_start_at: Time.zone.parse("2026-09-10 09:00"), expected_end_at: Time.zone.parse("2026-09-10 18:00"), status: :scheduled)
  end
  let!(:bob_shift) do
    ScheduledShift.create!(company: company, branch: branch, employee: bob, work_date: Date.parse("2026-09-12"),
      expected_start_at: Time.zone.parse("2026-09-12 09:00"), expected_end_at: Time.zone.parse("2026-09-12 18:00"), status: :completed)
  end

  before { get sign_in_for_test_path(email: owner_user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def shift_ids(body)
    JSON.parse(body)["scheduled_shifts"].map { |s| s["id"] }
  end

  it "filters by employee_name (partial, case-insensitive)" do
    get company_scheduled_shifts_path(company, format: :json), params: { employee_name: "alice" }
    ids = shift_ids(response.body)
    expect(ids).to include(alice_shift.id)
    expect(ids).not_to include(bob_shift.id)
  end

  it "filters by status" do
    get company_scheduled_shifts_path(company, format: :json), params: { status: "completed" }
    ids = shift_ids(response.body)
    expect(ids).to include(bob_shift.id)
    expect(ids).not_to include(alice_shift.id)
  end

  it "filters by from/to range on work_date" do
    get company_scheduled_shifts_path(company, format: :json), params: { from: "2026-09-11", to: "2026-09-13" }
    ids = shift_ids(response.body)
    expect(ids).to include(bob_shift.id)
    expect(ids).not_to include(alice_shift.id)
  end

  it "ignores bogus filter params instead of 500ing" do
    get company_scheduled_shifts_path(company, format: :json), params: { status: "hijack", from: "not-a-date", to: "%%%" }
    expect(response).to have_http_status(:ok)
    expect(shift_ids(response.body)).to include(alice_shift.id, bob_shift.id)
  end

  it "scopes to the company" do
    other = create(:company)
    other_branch = other.branches.first || create(:branch, company: other)
    other_employee = create(:employee, company: other).tap { |e| e.update!(name: "Alice Clone") }
    foreign = ScheduledShift.create!(company: other, branch: other_branch, employee: other_employee, work_date: Date.parse("2026-09-10"),
      expected_start_at: Time.zone.parse("2026-09-10 09:00"), expected_end_at: Time.zone.parse("2026-09-10 18:00"), status: :scheduled)
    get company_scheduled_shifts_path(company, format: :json), params: { employee_name: "alice" }
    expect(shift_ids(response.body)).not_to include(foreign.id)
  end
end
