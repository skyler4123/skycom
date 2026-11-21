# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reception::ShiftService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:employee) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }
  let(:now) { Time.utc(2026, 11, 20, 12, 0, 0) }

  it "returns the scheduled shift covering now" do
    template = create(:shift_template, company: company, branch: branch, name: "Morning")
    shift = create(:scheduled_shift, company: company, branch: branch, employee: employee)
    shift.update!(shift_template: template, work_date: now.to_date,
      expected_start_at: now - 1.hour, expected_end_at: now + 1.hour)

    result = described_class.call(employee: employee, branch: branch, now: now)

    expect(result[:name]).to eq("Morning")
    expect(result[:start_at]).to eq((now - 1.hour).iso8601)
    expect(result[:end_at]).to eq((now + 1.hour).iso8601)
  end

  it "returns nil when no shift covers now" do
    shift = create(:scheduled_shift, company: company, branch: branch, employee: employee)
    shift.update!(work_date: now.to_date, expected_start_at: now - 2.hours, expected_end_at: now - 1.hour)

    expect(described_class.call(employee: employee, branch: branch, now: now)).to be_nil
  end

  it "returns nil without an employee" do
    expect(described_class.call(employee: nil, branch: branch, now: now)).to be_nil
  end
end
