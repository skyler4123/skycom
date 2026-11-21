# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::DutyRosterService, type: :service do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }

  def employee(name)
    create(:employee, company: company, branch: branch, name: name)
  end

  it "counts only checked-in employees on a shift that covers now" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      on_duty = employee("Lekisha Dare")
      create_store_shift(
        company: company, branch: branch, employee: on_duty, name: "Morning",
        starts_at: Time.utc(2026, 11, 20, 8, 0, 0), ends_at: Time.utc(2026, 11, 20, 17, 0, 0)
      )

      assigned = employee("Assigned Only")
      ScheduledShift.create!(
        company: company, branch: branch, employee: assigned, work_date: Date.new(2026, 11, 20),
        expected_start_at: Time.utc(2026, 11, 20, 8, 0, 0),
        expected_end_at: Time.utc(2026, 11, 20, 17, 0, 0),
        status: :scheduled
      )

      on_leave = employee("On Leave")
      create_store_shift(
        company: company, branch: branch, employee: on_leave, name: "Morning",
        starts_at: Time.utc(2026, 11, 20, 8, 0, 0), ends_at: Time.utc(2026, 11, 20, 17, 0, 0)
      )
      AttendanceLeave.create!(
        company: company, branch: branch, employee: on_leave, leave_type: :paid,
        status: :approved, start_date: Date.new(2026, 11, 20), end_date: Date.new(2026, 11, 20), days: 1
      )

      payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20))

      expect(payload[:on_duty_count]).to eq(1)
      expect(payload[:staff].map { |row| row[:name] }).to eq([ "Lekisha Dare" ])
      expect(payload[:shift]).to include(name: "Morning", checked_in_count: 1)
    end
  end

  it "returns no shift when no scheduled shift covers now" do
    travel_to Time.utc(2026, 11, 20, 22, 0, 0) do
      payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20))

      expect(payload[:shift]).to be_nil
      expect(payload[:on_duty_count]).to eq(0)
    end
  end

  it "reports multiple shifts honestly when more than one covers now" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      first = employee("Morning One")
      create_store_shift(
        company: company, branch: branch, employee: first, name: "Morning",
        starts_at: Time.utc(2026, 11, 20, 8, 0, 0), ends_at: Time.utc(2026, 11, 20, 17, 0, 0)
      )
      second = employee("Midday Two")
      create_store_shift(
        company: company, branch: branch, employee: second, name: "Midday",
        starts_at: Time.utc(2026, 11, 20, 9, 0, 0), ends_at: Time.utc(2026, 11, 20, 18, 0, 0)
      )

      payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20))

      expect(payload[:on_duty_count]).to eq(2)
      expect(payload[:shift]).to include(name: "Multiple shifts", checked_in_count: 2, shift_count: 2)
    end
  end

  it "keeps everyone who checked in on a past date, without a cap" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      9.times do |index|
        record = employee("Employee #{index}")
        create_store_shift(
          company: company, branch: branch, employee: record, name: "Morning",
          starts_at: Time.utc(2026, 11, 20, 8, 0, 0), ends_at: Time.utc(2026, 11, 20, 17, 0, 0)
        )
      end

      payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20))

      expect(payload[:on_duty_count]).to eq(9)
      expect(payload[:staff].length).to eq(9)
    end
  end
end
