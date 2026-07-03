module Attendance
  class BreakDeductor
    def self.deduct(gross_minutes, shift_template, segments)
      new(gross_minutes, shift_template, segments).deduct
    end

    def initialize(gross_minutes, shift_template, segments)
      @gross = gross_minutes
      @template = shift_template
      @segments = segments
    end

    def deduct
      deducted = @gross

      return deducted if @segments.length > 1

      if @gross > 300 && @template&.unpaid_break_minutes
        deducted -= @template.unpaid_break_minutes
      end

      [ deducted, 0 ].max
    end
  end
end
