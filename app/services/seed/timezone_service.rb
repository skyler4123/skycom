module Seed
  class TimezoneService
    # A mapping of UTC offsets to representative cities.
    TIMEZONE_CITIES = {
      -12 => "Baker Island",
      -11 => "Pago Pago",
      -10 => "Honolulu",
      -9 => "Anchorage",
      -8 => "Los Angeles",
      -7 => "Denver",
      -6 => "Mexico City",
      -5 => "New York",
      -4 => "Santiago",
      -3 => "Buenos Aires",
      -2 => "South Georgia",
      -1 => "Cape Verde",
      0 => "London",
      1 => "Paris",
      2 => "Cairo",
      3 => "Moscow",
      4 => "Dubai",
      5 => "Karachi",
      6 => "Dhaka",
      7 => "Ho Chi Minh City",
      8 => "Shanghai",
      9 => "Tokyo",
      10 => "Sydney",
      11 => "Noumea",
      12 => "Auckland"
    }.freeze

    def self.create
      puts "Seeding Timezones..."

      (-12..12).each do |offset|
        city = TIMEZONE_CITIES[offset]
        name = "UTC#{format_offset(offset)} (#{city})"

        Timezone.find_or_create_by!(name: name) do |tz|
          tz.utc_offset = offset
          tz.description = "Standard timezone for #{city} (UTC#{format_offset(offset)})"
          puts "Created Timezone: #{name}"
        end
      end

      puts "Timezone seeding complete."
    end
    
    def self.format_offset(offset)
      sign = offset.positive? ? "+" : "-"
      sign = "" if offset.zero?
      "#{sign}#{offset.abs.to_s.rjust(2, '0')}:00"
    end

    private_class_method :format_offset
  end
end