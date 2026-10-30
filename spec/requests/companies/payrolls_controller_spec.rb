require "rails_helper"

RSpec.describe "Companies::PayrollsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }
  let(:employee) do
    create(:employee, company: company, monthly_salary_cents: 2_100_000, monthly_allowance_cents: 210_000)
  end

  before { get sign_in_for_test_path(email: owner_user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  it "index renders shell" do
    get company_payroll_path(company)
    expect(response).to have_http_status(:ok)
  end

  it "summary returns json" do
    get company_payroll_summary_path(company, format: :json), params: { month: "2026-08" }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["summary"]).to be_present
  end

  it "generates payrolls with real money from attendance months" do
    AttendanceMonth.create!(
      company: company, employee: employee, month: Date.parse("2026-08-01"),
      total_work_minutes: 10_080, total_present_days: 21, total_records: 21, total_overtime_minutes: 60
    )
    post company_payroll_generate_path(company, format: :json), params: { month: "2026-08" }
    expect(response).to have_http_status(:ok)
    get company_payroll_payrolls_path(company, format: :json), params: { month: "2026-08" }
    body = JSON.parse(response.body)
    expect(body["payrolls"].size).to eq(1)
    payroll = body["payrolls"].first
    expect(payroll["currency"]).to eq("usd")
    expect(payroll["base_amount_cents"]).to eq(2_100_000)
    expect(payroll["net_amount_cents"]).to eq(1_899_789)
  end

  it "includes total net pay in the summary" do
    AttendanceMonth.create!(
      company: company, employee: employee, month: Date.parse("2026-08-01"),
      total_work_minutes: 10_080, total_present_days: 21, total_records: 21, total_overtime_minutes: 60
    )
    post company_payroll_generate_path(company, format: :json), params: { month: "2026-08" }

    get company_payroll_summary_path(company, format: :json), params: { month: "2026-08" }

    body = JSON.parse(response.body)
    expect(body["summary"]["total_net_amount_cents"]).to eq(1_899_789)
    expect(body["summary"]["currency"]).to eq(company.currency)
  end

  it "shows a payroll with its money breakdown" do
    am = AttendanceMonth.create!(company: company, employee: employee, month: Date.parse("2026-08-01"), total_work_minutes: 100)
    payroll = Payroll.create!(
      company: company, employee: employee, month: Date.parse("2026-08-01"), attendance_month: am,
      status: :draft, currency: :usd, base_amount_cents: 100_000, net_amount_cents: 81_600,
      tax_amount_cents: 10_000, deduction_amount_cents: 8_400
    )
    get company_payroll_payroll_path(company, payroll.id, format: :json)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["payroll"]["id"]).to eq(payroll.id.to_s)
    expect(body["payroll"]["currency"]).to eq("usd")
    expect(body["payroll"]["base_amount_cents"]).to eq(100_000)
    expect(body["payroll"]["tax_amount_cents"]).to eq(10_000)
  end

  it "updates payroll status and notes" do
    am = AttendanceMonth.create!(company: company, employee: employee, month: Date.parse("2026-08-01"), total_work_minutes: 100)
    payroll = Payroll.create!(company: company, employee: employee, month: Date.parse("2026-08-01"), attendance_month: am, status: :draft)
    patch company_payroll_payroll_path(company, payroll.id, format: :json), params: { payroll: { status: "approved", notes: "ok" } }
    expect(response).to have_http_status(:ok)
    payroll.reload
    expect(payroll.status).to eq("approved")
    expect(payroll.notes).to eq("ok")
  end

  it "returns 404 for missing payroll" do
    get company_payroll_payroll_path(company, "00000000-0000-0000-0000-000000000000", format: :json)
    expect(response).to have_http_status(:not_found)
  end
end
