class Seed::ApplicationService
  def self.run(seed_number: 0)
    puts "\n\n🚀 Starting Full Database Seeding..."
    puts "========================================================="


    # Clear all seed-created data before reseeding.
    # Disable referential integrity to bypass PostgreSQL FK constraints (328 FKs).
    # Use unscoped.delete_all to:
    #   1) Bypass Rails-level callbacks (restrict_with_error, before_destroy guards)
    #   2) Handle Discard default_scope (unscoped removes discarded_at filter)
    #   3) Cover all models automatically (no manual table list to maintain)
    Rails.application.eager_load!
    system_tables = %w[
      schema_migrations ar_internal_metadata
      active_storage_blobs active_storage_attachments active_storage_variant_records
      systems
    ]
    ActiveRecord::Base.connection.disable_referential_integrity do
      ApplicationRecord.descendants.each do |model|
        next if system_tables.include?(model.table_name)
        next if model == ApplicationRecord || model.abstract_class?
        model.unscoped.delete_all
      end
    end

    # Global Data
    # Identify the platform by a hardcoded CODE, not ID.
    System.find_or_create_by!(code: "System") do |sa|
      sa.name = "System"
      sa.balance_cents = 0
      sa.currency_code = :usd
    end
    Seed::PaymentMethodService.create # Ensure global payment methods are seeded first
    Billing::SeedResourcesService.call # Seed global billing resource catalog (19 records)
    # User
    super_admin_1 = Seed::UserService.create(email: "super_admin_1@example.com", system_role: :super_admin)
    super_admin_2 = Seed::UserService.create(email: "super_admin_2@example.com", system_role: :super_admin)
    admin_1 = Seed::UserService.create(email: "admin_1@example.com", system_role: :admin)
    admin_2 = Seed::UserService.create(email: "admin_2@example.com", system_role: :admin)

    user_1 = Seed::UserService.create(email: "user_1@company1.com", system_role: :company_owner)
    user_2 = Seed::UserService.create(email: "user_1@company2.com", system_role: :company_owner)
    user_1.address = Seed::AddressService.create
    user_2.address = Seed::AddressService.create

    # Create company groups
    company_1 = Seed::CompanyService.create(
      user: user_1, name: "Grocery 1", email: "retail_us@company1.com",
      description: "A group for multiple retail branch branches",
      business_type: RETAIL_INIT_COMPANY_GROUP_BUSINESS_TYPE,
      country_code: :us, currency_code: :usd, timezone: :minus_5
    )
    company_2 = Seed::CompanyService.create(
      user: user_2, name: "Grocery VN", email: "retail_vn@company2.com",
      description: "A group for multiple retail branch branches",
      business_type: RETAIL_INIT_COMPANY_GROUP_BUSINESS_TYPE,
      country_code: :vn, currency_code: :vnd, timezone: :plus_7,
      address_line_1: "123 Le Loi Street", city: "Ho Chi Minh City"
    )
    company_3 = Seed::CompanyService.create(
      user: user_2, name: "Smile Dental Center", email: "hospital@company3.com",
      description: "A multi-specialty dental clinic group",
      business_type: :hospital,
      country_code: :vn, currency_code: :vnd, timezone: :plus_7
    )

    Seed::RetailEnrichService.new(company: company_1, user: user_1, email: "retail_us@company1.com")
    Seed::RetailEnrichService.new(company: company_2, user: user_2, email: "retail_vn@company2.com")
    Seed::HospitalEnrichService.new(company: company_3, user: user_2, email: "hospital@company3.com")

    self.puts_count

    puts "\n========================================================="
    puts "🎉 Seeding is complete! Database is ready to use. 🎉"
    puts "========================================================="
    # Clear cache to force sign in for current sign in account
    Rails.cache.clear
    true
  end

  # Prints a cleanly formatted summary of record counts for all models.
  def self.puts_count
    puts "\n📊 Seeding Summary (Record Counts)"
    puts "----------------------------------------"

    skip_models = [ ApplicationRecord, Current ]

    # Iterate through all model files
    Dir[Rails.root.to_s + "/app/**/models/*.rb"].each do |file|
      begin
        file_name = file.split("/").last
        class_name = file_name.sub(".rb", "").camelize

        # Safely get the model class
        model_class = class_name.constantize

        # Skip base classes and models that don't respond to count
        next if skip_models.include?(model_class) || !model_class.respond_to?(:count)

        # Print the count with aligned text
        # Using ljust to align the class names beautifully
        puts "  👉 #{model_class.to_s.ljust(25)}: #{model_class.count}"
      rescue NameError
        # Silently skip files that aren't valid class constants (e.g., concerns)
        next
      rescue => e
        puts "  ❌ Error processing #{class_name}: #{e.message}"
      end
    end
    puts "----------------------------------------"
  end
end
