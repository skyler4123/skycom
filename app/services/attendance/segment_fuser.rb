# Superseded by Strategies::PairedStrategy and Strategies::CheckInOnlyStrategy.
# Segment fusion logic is now embedded in each strategy's #fuse_* method.
module Attendance
  class SegmentFuser
    def self.fuse(logs)
      new(logs).fuse
    end

    def initialize(logs)
      @logs = logs.to_a.sort_by(&:logged_at)
    end

    def fuse
      return [] if @logs.empty?

      # Detect check_in-only scenario: no check_out events at all
      check_ins = @logs.select { |l| l.log_type == "check_in" }
      check_outs = @logs.select { |l| l.log_type == "check_out" }

      if check_outs.empty? && check_ins.length >= 1
        return fuse_check_in_only(check_ins)
      end

      fuse_paired
    end

    private

    def fuse_check_in_only(check_ins)
      first = check_ins.first
      last = check_ins.last
      duration = ((last.logged_at - first.logged_at) / 60).to_i
      [ {
        start_at: first.logged_at,
        end_at: last.logged_at,
        duration_minutes: duration,
        has_check_out: true,
        is_virtual: true
      } ]
    end

    def fuse_paired
      segments = []
      i = 0
      while i < @logs.length
        current = @logs[i]
        if current.log_type == "check_in"
          nxt = @logs[i + 1]
          if nxt && nxt.log_type == "check_out"
            segments << {
              start_at: current.logged_at,
              end_at: nxt.logged_at,
              duration_minutes: ((nxt.logged_at - current.logged_at) / 60).to_i,
              has_check_out: true
            }
            i += 2
          else
            segments << {
              start_at: current.logged_at,
              end_at: nil,
              duration_minutes: 0,
              has_check_out: false
            }
            i += 1
          end
        else
          i += 1
        end
      end
      segments
    end
  end
end
