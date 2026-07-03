module Attendance
  class SegmentFuser
    def self.fuse(logs)
      new(logs).fuse
    end

    def initialize(logs)
      @logs = logs.to_a.sort_by(&:logged_at)
    end

    def fuse
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
