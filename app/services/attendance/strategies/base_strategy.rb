# Base class for attendance resolution strategies.
# Each strategy implements #call(logs, employee, date, shift_template) and
# returns { status:, net_minutes:, segments:, late_minutes:, ... }.
module Attendance
  module Strategies
    class BaseStrategy
      def call(logs, employee, date, shift_template)
        raise NotImplementedError
      end

      protected

      def haversine_distance(lat1, lon1, lat2, lon2)
        rad = ->(deg) { deg * Math::PI / 180 }
        dlat = rad.call(lat2 - lat1)
        dlon = rad.call(lon2 - lon1)
        a = Math.sin(dlat / 2)**2 + Math.cos(rad.call(lat1)) * Math.cos(rad.call(lat2)) * Math.sin(dlon / 2)**2
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
        6_371_000 * c
      end
    end
  end
end
