module Attendance
  module Strategies
    class CheckInOnlyStrategy < BaseStrategy
      def call(logs, employee, date, shift_template)
        check_ins = logs.to_a.select { |l| l.log_type == "check_in" }.sort_by(&:logged_at)
        return absent_result if check_ins.empty?

        first = check_ins.first
        last = check_ins.last
        duration = ((last.logged_at - first.logged_at) / 60).to_i

        segments = [ {
          start_at: first.logged_at,
          end_at: last.logged_at,
          duration_minutes: duration,
          has_check_out: true,
          is_virtual: true
        } ]

        gross = duration
        net = deduct_break(gross, shift_template, segments)
        match_policy(net, segments, shift_template, employee, date)
      end

      private

      def deduct_break(gross, template, segments)
        deducted = gross
        return deducted if segments.length > 1
        if gross > 300 && template&.unpaid_break_minutes
          deducted -= template.unpaid_break_minutes
        end
        [ deducted, 0 ].max
      end

      def match_policy(net, segments, template, employee, date)
        full_day = template&.full_day_minutes || 480
        case template&.policy_type
        when "pure_flexible" then flexible_match(net, full_day)
        when "core_hours_flexible" then core_hours_match(net, segments, template, date, full_day)
        else fixed_match(net, segments, template, employee, date, full_day)
        end
      end

      def flexible_match(net, full_day)
        if net >= full_day
          success_result(net - full_day, net, segments)
        elsif net >= full_day / 2
          half_day_result(net, segments)
        else
          absent_result
        end
      end

      def fixed_match(net, segments, template, employee, date, full_day)
        late = 0
        first = segments.first
        if first && template
          grace = template.grace_period_minutes || 15
          shift = ScheduledShift.find_by(employee: employee, work_date: date)
          if shift && first[:start_at] && first[:start_at] > shift.expected_start_at + grace.minutes
            late = ((first[:start_at] - shift.expected_start_at) / 60).to_i
          end
        end

        if net >= full_day
          if late > 0
            { status: :late, late_minutes: late, early_leave_minutes: 0, overtime_minutes: [ net - full_day, 0 ].max, net_minutes: net, segments: segments }
          else
            success_result(net - full_day, net, segments)
          end
        elsif net >= full_day / 2
          half_day_result(net, segments)
        else
          absent_result
        end
      end

      def core_hours_match(net, segments, template, date, full_day)
        covers_core = false
        if template&.core_start_time && template&.core_end_time
          core_start = date.to_time.change(hour: template.core_start_time.hour, min: template.core_start_time.min)
          core_end = date.to_time.change(hour: template.core_end_time.hour, min: template.core_end_time.min)
          covers_core = segments.any? { |s| s[:start_at] && s[:end_at] && s[:start_at] <= core_start && s[:end_at] >= core_end }
        end

        if net >= full_day
          if covers_core
            success_result(net - full_day, net, segments)
          else
            { status: :present, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0, net_minutes: net, segments: segments, policy_violation: "missed_core_hours" }
          end
        elsif net >= full_day / 2
          half_day_result(net, segments)
        else
          absent_result
        end
      end

      def success_result(overtime, net, segs)
        { status: :present, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: overtime, net_minutes: net, segments: segs }
      end

      def half_day_result(net, segs)
        { status: :half_day, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0, net_minutes: net, segments: segs }
      end

      def absent_result
        { status: :absent, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0, net_minutes: 0, segments: [] }
      end
    end
  end
end
