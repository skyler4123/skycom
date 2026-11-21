# frozen_string_literal: true

# StoreManager::DutyRosterService — the real "who is here" answer for one
# branch day.
#
# On duty means: an approved leave does not cover the day, a scheduled shift
# covers the moment (today) or exists that day (past), and the employee's latest
# attendance log is a check-in (today) or they checked in at some point (past).
# No assignment-only rows and no staff cap.
#
# Docs: docs/HR.md, docs/business_analysis/06-store-manager.md
class StoreManager::DutyRosterService
  def self.call(company:, branch:, date:, now: Time.current)
    new(company: company, branch: branch, date: date, now: now).call
  end

  def initialize(company:, branch:, date:, now:)
    @company = company
    @branch = branch
    @date = date.to_date
    @now = now
  end

  def call
    {
      shift: shift_payload,
      staff: staff_payload,
      on_duty_count: staff_payload.length,
      scheduled_count: scheduled_shifts.length
    }
  end

  private

  attr_reader :company, :branch, :date, :now

  def today?
    @today ||= LocalTime.today(branch, at: now) == date
  end

  def day_range
    @day_range ||= LocalTime.day_range(date, branch)
  end

  def scheduled_shifts
    @scheduled_shifts ||= company.scheduled_shifts
      .where(branch_id: branch.id, work_date: date, discarded_at: nil)
      .includes(:employee, :shift_template)
      .to_a
      .select { |shift| today? ? covers_now?(shift) : true }
  end

  def covers_now?(shift)
    shift.expected_start_at <= now && shift.expected_end_at > now
  end

  def leave_employee_ids
    @leave_employee_ids ||= company.attendance_leaves
      .where(status: :approved)
      .where("start_date <= ? AND end_date >= ?", date, date)
      .pluck(:employee_id)
      .to_set
  end

  def attendance_logs
    @attendance_logs ||= company.attendance_logs
      .where(employee_id: scheduled_shifts.map(&:employee_id).uniq)
      .where(logged_at: day_range)
      .order(:logged_at)
      .to_a
  end

  def latest_logs
    @latest_logs ||= attendance_logs.group_by(&:employee_id).transform_values(&:last)
  end

  def checked_in_at
    @checked_in_at ||= attendance_logs
      .select(&:log_type_check_in?)
      .group_by(&:employee_id)
      .transform_values { |logs| logs.map(&:logged_at).max }
  end

  def duty_shifts
    @duty_shifts ||= scheduled_shifts.select do |shift|
      employee_id = shift.employee_id
      next false if leave_employee_ids.include?(employee_id)

      if today?
        latest_logs[employee_id]&.log_type_check_in?
      else
        checked_in_at.key?(employee_id)
      end
    end
  end

  def staff_payload
    @staff_payload ||= duty_shifts
      .uniq(&:employee_id)
      .sort_by { |shift| shift.employee.name.to_s }
      .map do |shift|
        employee = shift.employee
        {
          employee_id: employee.id,
          name: employee.name,
          role: employee_role(employee),
          checked_in_at: LocalTime.utc_iso(checked_in_at[employee.id]),
          status_label: "Checked in"
        }
      end
  end

  def shift_payload
    @shift_payload ||= begin
      groups = scheduled_shifts.group_by do |shift|
        [ shift.shift_template_id, shift.expected_start_at, shift.expected_end_at ]
      end
      return nil if groups.empty?

      rows = groups.map do |_key, shifts|
        first = shifts.first
        on_duty = shifts.map(&:employee_id).uniq.count do |employee_id|
          staff_payload.any? { |row| row[:employee_id] == employee_id }
        end
        {
          name: first.shift_template&.name.presence || "Scheduled shift",
          starts_at: LocalTime.utc_iso(first.expected_start_at),
          ends_at: LocalTime.utc_iso(first.expected_end_at),
          checked_in_count: on_duty
        }
      end

      active_rows = rows.select { |row| row[:checked_in_count].positive? }
      if active_rows.length > 1
        {
          name: "Multiple shifts",
          starts_at: active_rows.map { |row| row[:starts_at] }.min,
          ends_at: active_rows.map { |row| row[:ends_at] }.max,
          checked_in_count: staff_payload.length,
          shift_count: active_rows.length
        }
      else
        row = active_rows.first || rows.first
        row.merge(shift_count: 1)
      end
    end
  end

  def employee_role(employee)
    role = employee.category&.name.presence
    return nil if role.blank? || role == "Employees"

    role
  end
end
