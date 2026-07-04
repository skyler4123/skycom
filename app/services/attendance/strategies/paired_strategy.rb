module Attendance
  module Strategies
    class PairedStrategy < BaseStrategy
      def call(logs, employee, date, shift_template)
        sorted = logs.to_a.sort_by(&:logged_at)
        segments = fuse_paired(sorted)

        if segments.empty? || segments.none? { |s| s[:has_check_out] }
          return absent_result
        end

        gross = segments.select { |s| s[:has_check_out] }.sum { |s| s[:duration_minutes] }
        net = deduct_break(gross, shift_template, segments)
        match_policy(net, segments, shift_template, employee, date)
      end

      private

      def fuse_paired(logs)
        segments = []
        i = 0
        while i < logs.length
          current = logs[i]
          if current.log_type == "check_in"
            nxt = logs[i + 1]
            if nxt && nxt.log_type == "check_out"
              segments << segment(current.logged_at, nxt.logged_at, true)
              i += 2
            else
              segments << segment(current.logged_at, nil, false)
              i += 1
            end
          else
            i += 1
          end
        end
        segments
      end

      def segment(start_at, end_at, has_check_out)
        dur = end_at ? ((end_at - start_at) / 60).to_i : 0
        { start_at: start_at, end_at: end_at, duration_minutes: dur, has_check_out: has_check_out }
      end

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
          success_result(net - full_day)
        elsif net >= full_day / 2
          half_day_result
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
            { status: :late, late_minutes: late, early_leave_minutes: 0, overtime_minutes: [ net - full_day, 0 ].max }
          else
            success_result(net - full_day)
          end
        elsif net >= full_day / 2
          half_day_result
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
            success_result(net - full_day)
          else
            { status: :present, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0, policy_violation: "missed_core_hours" }
          end
        elsif net >= full_day / 2
          half_day_result
        else
          absent_result
        end
      end

      def success_result(overtime)
        { status: :present, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: overtime, net_minutes: 0, segments: [] }
      end

      def half_day_result
        { status: :half_day, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0, net_minutes: 0, segments: [] }
      end

      def absent_result
        { status: :absent, late_minutes: 0, early_leave_minutes: 0, overtime_minutes: 0, net_minutes: 0, segments: [] }
      end
    end
  end
end
