# spec/services/seed/scheduled_shift_service_spec.rb
require 'rails_helper'

RSpec.describe Seed::ScheduledShiftService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:employee) { create(:employee, company: company, branch: branch) }
  let(:template) { create(:shift_template, company: company, branch: branch) }
  let(:work_date) { Date.current + 2.days }

  def upsert_attrs(overrides = {})
    {
      company: company, branch: branch, employee: employee,
      shift_template: template, work_date: work_date,
      expected_start_at: work_date.to_time.change(hour: 7),
      expected_end_at: work_date.to_time.change(hour: 15),
      status: :scheduled
    }.merge(overrides)
  end

  describe ".upsert!" do
    it "creates the shift when none exists" do
      expect { described_class.upsert!(**upsert_attrs) }
        .to change(ScheduledShift, :count).by(1)
    end

    it "reuses the existing row when a concurrent writer created it first (no unique violation)" do
      # Simulates Attendance::CheckInSimulatorJob#ensure_today_shift winning the race:
      # template-less row, already checked in (active).
      existing = ScheduledShift.create!(
        company: company, branch: branch, employee: employee,
        shift_template: nil, work_date: work_date,
        expected_start_at: work_date.to_time.change(hour: 9),
        expected_end_at: work_date.to_time.change(hour: 18),
        status: :active
      )

      expect { described_class.upsert!(**upsert_attrs) }
        .not_to change(ScheduledShift, :count)

      expect(existing.reload.shift_template).to eq(template)
      expect(existing.status).to eq("scheduled")
    end
  end
end
