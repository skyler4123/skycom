# This service seeds the database with Booking records. Each booking connects
# a "booker" (e.g., an Employee) to a "bookable" resource (e.g., a Facility)
# within the context of a Company.

class Seed::BookingService
  # Configuration for the number of bookings to create per company
  BOOKINGS_PER_COMPANY = 5

  def self.run
    puts "Seeding Booking records..."

    # Get enum keys once before the loop for efficiency.
    statuses = Booking.statuses.keys
    business_types = Booking.business_types.keys

    Company.all.each do |company|
      # Get potential bookers (employees) and bookable items (facilities) for the company
      bookers = company.employees
      bookable_items = company.facilities

      # Skip if there's nothing to book or no one to book
      next if bookers.empty? || bookable_items.empty?

      BOOKINGS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        booker = bookers.sample
        bookable = bookable_items.sample

        Booking.create!(
          company: company,
          appoint_from: booker,
          appoint_to: bookable,
          name: "Booking for #{bookable.name} by #{booker.name}",
          description: "Booking ##{i + 1} for company #{company.name}.",
          code: "BOOK-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Booking.count} Booking records."
  end
end