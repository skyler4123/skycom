class Seed::PropertyPopulator
  STRING_VALUES = {
    "Skin Type Suitability" => [ "Oily", "Dry", "Combination", "Normal", "Sensitive" ],
    "Key Ingredients" => [ "Hyaluronic Acid", "Retinol", "Vitamin C", "Niacinamide", "Salicylic Acid", "Ceramides" ],
    "Formulation" => [ "Liquid", "Powder", "Cream", "Gel", "Foam", "Stick" ],
    "Scent" => [ "Floral", "Citrus", "Woody", "Fresh", "Oriental", "Powdery" ],
    "Material" => [ "Gold", "Silver", "Stainless Steel", "Titanium", "Ceramic", "Leather" ],
    "Color" => [ "Black", "White", "Red", "Blue", "Green", "Rose Gold", "Silver" ],
    "Size" => [ "Small", "Medium", "Large", "Extra Large", "One Size" ],
    "Volume" => [ "30ml", "50ml", "100ml", "150ml", "200ml", "250ml" ],
    "Weight" => [ "50g", "100g", "200g", "500g", "1kg" ],
    "Duration" => [ "30 minutes", "45 minutes", "60 minutes", "90 minutes", "120 minutes" ],
    "Notes" => [ "Best seller", "New arrival", "Limited edition", "Seasonal", "Premium" ],
    "Location" => [ "Floor 1", "Floor 2", "Basement", "Warehouse A", "Warehouse B" ],
    "Certificate" => [ "ISO 9001", "ISO 14001", "GMP Certified", "FDA Approved", "CE Marked" ],
    "Contact" => [ "Primary", "Secondary", "Emergency", "Billing", "Support" ],
    "Status" => [ "Active", "Inactive", "Pending", "Under Review", "Approved" ],
    "Department" => [ "Sales", "Marketing", "Operations", "Finance", "HR" ],
    "Priority" => [ "Low", "Medium", "High", "Critical", "Urgent" ],
    "Type" => [ "Standard", "Premium", "Deluxe", "Basic", "Pro" ],
    "Payment" => [ "Cash", "Credit Card", "Bank Transfer", "E-Wallet", "Installment" ],
    "Shipping" => [ "Standard", "Express", "Next Day", "Same Day", "International" ],
    "Section" => [ "Aisle 1", "Aisle 2", "Aisle 3", "Aisle 4", "Aisle 5" ],
    "Rating" => [ "1 Star", "2 Stars", "3 Stars", "4 Stars", "5 Stars" ],
    "Season" => [ "Spring", "Summer", "Fall", "Winter", "All Season" ],
    "Room" => [ "Room A", "Room B", "Room C", "Room D", "Room E" ],
    "Provider" => [ "Internal", "External", "Third Party", "In-House", "Outsourced" ],
    "Reference" => [ "REF-001", "REF-002", "REF-003", "REF-004", "REF-005" ],
    "Code" => [ "CODE-A", "CODE-B", "CODE-C", "CODE-D", "CODE-E" ],
    "Spec" => [ "Spec v1.0", "Spec v2.0", "Spec v3.0", "Spec v4.0", "Spec v5.0" ],
    "Standard" => [ "IFRS", "VAS", "GAAP", "IAS", "Local" ],
    "Bank" => [ "Vietcombank", "Techcombank", "ACB", "BIDV", "VietinBank" ],
    "Channel" => [ "Online", "Offline", "Phone", "Email", "Chat" ],
    "Platform" => [ "Shopify", "WooCommerce", "Lazada", "Shopee", "Tiki" ],
    "Campaign" => [ "Summer Sale", "Black Friday", "New Year", "Loyalty", "Referral" ],
    "Category" => [ "Premium", "Standard", "Budget", "Luxury", "Economy" ],
    "Tier" => [ "Gold", "Silver", "Bronze", "Platinum", "Diamond" ],
    "Frequency" => [ "Daily", "Weekly", "Monthly", "Quarterly", "Yearly" ],
    "Method" => [ "Manual", "Automated", "Hybrid", "Batch", "Real-time" ],
    "System" => [ "POS A", "POS B", "ERP", "CRM", "WMS" ],
    "Zone" => [ "North", "South", "East", "West", "Central" ],
    "Tag" => [ "Featured", "Bestseller", "New", "Sale", "Exclusive" ],
    "Feature" => [ "Waterproof", "Shockproof", "Dustproof", "Heat Resistant", "Eco-friendly" ],
    "Coverage" => [ "Basic", "Extended", "Premium", "Complete", "None" ],
    "Origin" => [ "Vietnam", "USA", "Japan", "Korea", "France", "Germany", "Italy" ],
    "Language" => [ "Vietnamese", "English", "Japanese", "Korean", "French" ],
    "Form Factor" => [ "Compact", "Full-size", "Portable", "Desktop", "Handheld" ],
    "Unit" => [ "Piece", "Box", "Set", "Pack", "Carton" ],
    "Finish" => [ "Matte", "Glossy", "Satin", "Metallic", "Pearlescent" ],
    "Style" => [ "Modern", "Classic", "Vintage", "Contemporary", "Minimalist" ],
    "Audit" => [ "Internal", "External", "Regulatory", "Compliance", "Security" ],
    "Policy" => [ "Standard", "Premium", "Enterprise", "Basic", "Custom" ],
    "Mode" => [ "Automatic", "Manual", "Semi-automatic", "Guided", "Supervised" ],
    "Rate" => [ "Fixed", "Variable", "Tiered", "Flat", "Progressive" ],
    "Alignment" => [ "Left", "Right", "Center", "Justified", "Distributed" ],
    "Permission" => [ "Read", "Write", "Admin", "Restricted", "Full" ],
    "Capacity" => [ "10 units", "25 units", "50 units", "100 units", "500 units" ],
    "Temperature" => [ "Cold", "Cool", "Room", "Warm", "Hot" ],
    "Risk" => [ "Low", "Medium", "High", "Critical", "None" ],
    "Warranty" => [ "3 months", "6 months", "1 year", "2 years", "5 years" ],
    "Cable" => [ "USB-C", "Lightning", "Micro-USB", "HDMI", "Thunderbolt" ],
    "Plan" => [ "Starter", "Growth", "Business", "Enterprise", "Custom" ],
    "Package" => [ "Basic", "Standard", "Premium", "Deluxe", "Ultimate" ],
    "Agent" => [ "Support Agent", "Sales Agent", "Service Agent", "Field Agent", "Remote Agent" ],
    "Team" => [ "Alpha", "Beta", "Gamma", "Delta", "Epsilon" ],
    "Level" => [ "Entry", "Junior", "Mid", "Senior", "Lead" ],
    "Account" => [ "Checking", "Savings", "Business", "Investment", "Payroll" ],
    "Direction" => [ "Inbound", "Outbound", "Cross-dock", "Internal", "External" ],
    "Role" => [ "Admin", "Editor", "Viewer", "Contributor", "Manager" ]
  }.freeze

  LABEL_MATCHERS = STRING_VALUES.keys.map { |k| [ /#{Regexp.escape(k)}/i, STRING_VALUES[k] ] }.freeze

  def self.populate(record)
    mapping = record.category&.default_property_mapping
    return unless mapping

    record.property_mapping ||= mapping

    mapping.property_metadata.each do |config|
      key = config["key"]
      next if key.blank?

      label = config["label"]
      next if label.blank?
      next unless record.class.column_names.include?(key)

      type = config["type"] || key.split("_")[1]

      record[key] = case type
      when "string"  then random_string_value(label)
      when "integer" then rand(1..250)
      when "boolean" then [ true, false ].sample
      when "decimal" then rand(1.0..500.0).round(2)
      when "datetime" then Faker::Time.between(from: 2.years.ago, to: 2.years.from_now)
      when "text"    then Faker::Lorem.paragraph(sentence_count: 3)
      end
    end
  end

  def self.random_string_value(label)
    LABEL_MATCHERS.each do |pattern, values|
      return values.sample if label.match?(pattern)
    end
    Faker::Lorem.word
  end
end
