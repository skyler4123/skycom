class Seed::ApplicationService
  def self.run(seed_number: 0)
    puts "\n\n🚀 Starting Full Database Seeding..."
    puts "========================================================="

    # Clear global data before seeding
    User.destroy_all
    PaymentMethod.destroy_all
    Brand.destroy_all

    # Global Data
    # Identify the platform by a hardcoded CODE, not ID.
    System.find_or_create_by!(code: "System") do |sa|
      sa.name = "System"
      sa.balance_cents = 0
      sa.currency = "USD"
    end
    Seed::PaymentMethodService.create # Ensure global payment methods are seeded first
    Seed::BrandService.create # Seed global brands

    # User
    admin_1 = Seed::UserService.create(email: "admin_1@example.com", system_role: 1)
    admin_2 = Seed::UserService.create(email: "admin_2@example.com", system_role: 1)

    user_1 = Seed::UserService.create(email: "user_1@example.com")
    user_2 = Seed::UserService.create(email: "user_2@example.com")
    user_3 = Seed::UserService.create(email: "user_3@example.com")
    user_1.address = Seed::AddressService.create
    user_2.address = Seed::AddressService.create
    user_3.address = Seed::AddressService.create

    # Create company groups
    Seed::MultiCompanyGroupService.new(user: user_1)
    # Seed::MultiCompanyGroupService.new(user: user_2)


    self.puts_count

    puts "\n========================================================="
    puts "🎉 Seeding is complete! Database is ready to use. 🎉"
    puts "========================================================="
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
