# frozen_string_literal: true

# LocalTime — the single conversion point between a location's wall clock and
# UTC. Storage and transport stay UTC; calendar days and wall-clock input use the
# timezone that owns the record.
#
# Docs: docs/TIME_DISPLAY.md
module LocalTime
  module_function

  # @param source [Object, String, Integer, nil] record with #timezone, enum key, or offset
  # @return [Integer] UTC offset in seconds
  def offset_seconds(source)
    offset_hours(source) * 3600
  end

  # @param source [Object, String, Integer, nil] record with #timezone, enum key, or offset
  # @return [Integer] UTC offset in hours
  def offset_hours(source)
    value = source.respond_to?(:timezone) ? source.timezone : source
    return 0 if value.blank?
    return value if value.is_a?(Numeric)

    TIMEZONES.fetch(value.to_s.to_sym) { 0 }
  end

  # @param source [Object, String, Integer, nil]
  # @param at [Time]
  # @return [Time] `at` expressed at the location's UTC offset
  def now(source, at: Time.current)
    at.getlocal(offset_seconds(source))
  end

  # @param source [Object, String, Integer, nil]
  # @param at [Time]
  # @return [Date] the location's calendar day
  def today(source, at: Time.current)
    now(source, at: at).to_date
  end

  # @param date [Date]
  # @param source [Object, String, Integer, nil]
  # @return [Range<Time>] UTC instants for the location's calendar day
  def day_range(date, source)
    date = date.to_date
    start = Time.new(date.year, date.month, date.day, 0, 0, 0, offset_seconds(source))
    start...(start + 1.day)
  end

  # Parses a wall-clock date + time in the location's timezone and returns UTC.
  # @param date [Date, String]
  # @param time [String]
  # @param source [Object, String, Integer, nil]
  # @return [Time, nil]
  def parse(date, time, source)
    return nil if date.blank? || time.blank?

    match = time.to_s.match(/\A\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*\z/)
    return nil unless match

    hour = match[1].to_i
    minute = match[2].to_i
    second = match[3].to_i
    return nil if hour > 23 || minute > 59 || second > 59

    day = date.to_date
    Time.new(day.year, day.month, day.day, hour, minute, second, offset_seconds(source)).utc
  rescue ArgumentError, TypeError, NoMethodError
    nil
  end

  # @param time [Time, nil]
  # @return [String, nil] ISO 8601 UTC
  def utc_iso(time)
    time&.utc&.iso8601
  end
end
