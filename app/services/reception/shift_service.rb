# frozen_string_literal: true

# Reception::ShiftService — the signed-in employee's scheduled shift covering
# the current branch time, or nil. The console never invents a shift from the
# clock.
# Docs: docs/OPERATIONS.md, docs/HR.md
class Reception::ShiftService
  def self.call(employee:, branch:, now: Time.current)
    new(employee: employee, branch: branch, now: now).call
  end

  def initialize(employee:, branch:, now:)
    @employee = employee
    @branch = branch
    @now = now
  end

  def call
    return nil unless employee

    shift = employee.scheduled_shifts
      .where(branch: branch, work_date: LocalTime.today(branch, at: now))
      .where(status: %i[scheduled active])
      .where("expected_start_at <= ? AND expected_end_at >= ?", now, now)
      .order(:expected_start_at)
      .first
    return nil unless shift

    {
      name: shift.shift_template&.name.presence || "Scheduled shift",
      start_at: LocalTime.utc_iso(shift.expected_start_at),
      end_at: LocalTime.utc_iso(shift.expected_end_at)
    }
  end

  private

  attr_reader :employee, :branch, :now
end
