# frozen_string_literal: true

require "rails_helper"

RSpec.describe MobileHelper, type: :helper do
  describe "#mobile_greeting" do
    it "greets the first name with a time-appropriate salutation" do
      expect(helper.mobile_greeting("Hosea Schuster")).to match(/\A(Good morning|Good afternoon|Good evening), Hosea\z/)
    end

    it "falls back to a neutral greeting when the name is blank" do
      expect(helper.mobile_greeting(nil)).to match(/\A(Good morning|Good afternoon|Good evening), there\z/)
    end
  end

  describe "#mobile_initials" do
    it "returns the first letter of the first two name parts" do
      expect(helper.mobile_initials("Hosea Schuster")).to eq("HS")
    end

    it "returns one letter for a single name" do
      expect(helper.mobile_initials("Hosea")).to eq("H")
    end

    it "returns a placeholder for a blank name" do
      expect(helper.mobile_initials(nil)).to eq("?")
    end
  end

  describe "#mobile_duration" do
    it "formats minutes as hours and zero-padded minutes" do
      expect(helper.mobile_duration(5_100)).to eq("85h 00m")
    end

    it "formats a partial hour" do
      expect(helper.mobile_duration(95)).to eq("1h 35m")
    end

    it "returns zero for a blank value" do
      expect(helper.mobile_duration(nil)).to eq("0h 00m")
    end
  end

  describe "#mobile_duration_from_seconds" do
    it "converts worked seconds to hours and minutes" do
      expect(helper.mobile_duration_from_seconds(28_800)).to eq("8h 00m")
    end
  end

  describe "#mobile_time" do
    it "formats a timestamp with a 12-hour clock" do
      expect(helper.mobile_time(Time.zone.parse("2026-10-26 09:00"))).to eq("09:00 AM")
    end

    it "formats a timestamp in a fixed UTC offset" do
      expect(helper.mobile_time(Time.zone.parse("2026-10-29 17:30"), utc_offset: 7 * 3600)).to eq("12:30 AM")
    end

    it "returns a dash for a blank timestamp" do
      expect(helper.mobile_time(nil)).to eq("—")
    end
  end

  describe "#mobile_date" do
    it "formats a date with a leading zero and full month" do
      expect(helper.mobile_date(Date.new(2026, 10, 1))).to eq("01 October 2026")
    end
  end

  describe "#mobile_weekday" do
    it "returns the short weekday name" do
      expect(helper.mobile_weekday(Date.new(2026, 10, 1))).to eq("Thu")
    end
  end

  describe "#mobile_month_label" do
    it "formats the month and year" do
      expect(helper.mobile_month_label(Date.new(2026, 10, 1))).to eq("October 2026")
    end
  end

  describe "#mobile_month_param" do
    it "formats the month for a query parameter" do
      expect(helper.mobile_month_param(Date.new(2026, 10, 1))).to eq("2026-10")
    end
  end

  describe "#mobile_attendance_rate" do
    it "calculates the present rate from the monthly rollup" do
      month = AttendanceMonth.new(total_records: 20, total_present_days: 19)

      expect(helper.mobile_attendance_rate(month)).to eq("95.0%")
    end

    it "returns a dash when there are no records" do
      month = AttendanceMonth.new(total_records: 0, total_present_days: 0)

      expect(helper.mobile_attendance_rate(month)).to eq("—")
    end
  end

  describe "#mobile_business_type_label" do
    it "labels the attendance request types" do
      expect(helper.mobile_business_type_label("remote_work")).to eq("Remote Work")
    end
  end

  describe "#mobile_employee_type_label" do
    it "labels the employee contract types" do
      expect(helper.mobile_employee_type_label("part_time")).to eq("Part-Time")
    end
  end

  describe "#mobile_money" do
    it "formats USD cents with two decimals" do
      expect(helper.mobile_money(486_540, :usd)).to eq("$4,865.40")
    end

    it "formats VND cents without decimals" do
      expect(helper.mobile_money(6_000_000_000, :vnd)).to eq("60,000,000 ₫")
    end

    it "formats a missing amount as zero" do
      expect(helper.mobile_money(nil, :usd)).to eq("$0.00")
    end
  end

  describe "#mobile_payroll_tax_label" do
    it "labels the combined statutory rate" do
      expect(helper.mobile_payroll_tax_label).to eq("Statutory (18.4%)")
    end
  end
end
