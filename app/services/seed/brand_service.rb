# This service seeds the database with Brand records. These are not tied
# to a specific company. It uses enums defined in the Brand model and
# simulates soft deletion for some records.

class Seed::BrandService
  # An array of popular company/brand names for seeding.
  POPULAR_BRANDS = [
    "Apple", "Samsung", "Google", "Microsoft", "Amazon", "Facebook", "Tesla",
    "Toyota", "Coca-Cola", "McDonald's", "Disney", "Nike", "Adidas", "Louis Vuitton",
    "Gucci", "Mercedes-Benz", "BMW", "Intel", "IBM", "Cisco", "Oracle", "SAP",
    "Accenture", "Deloitte", "PwC", "KPMG", "EY", "GE", "Honda", "Ford", "Pepsi",
    "Starbucks", "IKEA", "H&M", "Zara", "Uniqlo", "L'Oréal", "Gillette", "Pampers",
    "Colgate", "Nescafé", "Red Bull", "Mastercard", "Visa", "American Express",
    "J.P. Morgan", "Goldman Sachs", "Morgan Stanley", "Netflix", "Spotify"
  ].freeze

  def self.create
    # Get enum keys once before the loop for efficiency.
    statuses = Brand.statuses.keys
    business_types = Brand.business_types.keys

    puts "Seeding #{POPULAR_BRANDS.count} Brand records..."

    POPULAR_BRANDS.each do |brand_name|
      # Randomly decide whether to mark the record as discarded
      should_discard = rand(10) == 0 # 10% chance of being discarded

      Brand.create!(
        name: brand_name,
        description: "Official brand page for #{brand_name}.",
        code: "BR-#{SecureRandom.hex(4).upcase}",
        status: statuses.sample,
        business_type: business_types.sample,
        # Set a past timestamp for discarded_at if the record is to be soft-deleted
        discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
      )
    end
    puts "Successfully created #{Brand.count} Brand records."
  end
end
