module Attendance
  class PolicyMatcher
    def self.match(net_minutes, segments, shift_template, employee, date)
      new(net_minutes, segments, shift_template, employee, date).match
    end

    def initialize(net_minutes, segments, shift_template, employee, date)
      @net = net_minutes
      @segments = segments
      @template = shift_template
      @employee = employee
      @date = date
    end

    def match
      full_day = @template&.full_day_minutes || 480

      case @template&.policy_type
      when "pure_flexible"
        flexible_match(full_day)
      when "core_hours_flexible"
        core_hours_match(full_day)
      else
        fixed_match(full_day)
      end
    end

    private

    def flexible_match(full_day)
      if @net >= full_day
        { status: :present, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: [ @net - full_day, 0 ].max }
      elsif @net >= full_day / 2
        { status: :half_day, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0 }
      else
        { status: :absent, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0 }
      end
    end

    def fixed_match(full_day)
      first_segment = @segments.first
      late = 0
      if first_segment && @template
        grace = @template.grace_period_minutes || 15
        shift = ScheduledShift.find_by(employee: @employee, work_date: @date)
        if shift && first_segment[:start_at] && first_segment[:start_at] > shift.expected_start_at + grace.minutes
          late = ((first_segment[:start_at] - shift.expected_start_at) / 60).to_i
        end
      end

      if @net >= full_day
        if late > 0
          { status: :late, late_minutes: late, early_leave_minutes: 0, overtime_minutes: [ @net - full_day, 0 ].max }
        else
          { status: :present, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: [ @net - full_day, 0 ].max }
        end
      elsif @net >= full_day / 2
        { status: :half_day, late_minutes: late, early_leave_minutes: 0, overtime_minutes: 0 }
      else
        { status: :absent, late_minutes: late, early_leave_minutes: 0, overtime_minutes: 0 }
      end
    end

    def core_hours_match(full_day)
      covers_core = false
      if @template&.core_start_time && @template&.core_end_time
        core_start = @date.to_time.change(hour: @template.core_start_time.hour, min: @template.core_start_time.min)
        core_end = @date.to_time.change(hour: @template.core_end_time.hour, min: @template.core_end_time.min)
        covers_core = @segments.any? { |s| s[:start_at] && s[:end_at] && s[:start_at] <= core_start && s[:end_at] >= core_end }
      end

      if @net >= full_day
        if covers_core
          { status: :present, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: [ @net - full_day, 0 ].max }
        else
          { status: :present, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0, policy_violation: "missed_core_hours" }
        end
      elsif @net >= full_day / 2
        { status: :half_day, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0 }
      else
        { status: :absent, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0 }
      end
    end
  end
end
