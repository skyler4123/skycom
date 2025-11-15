class Seed::ApplicationService
  def self.run(seed_number: 0)
    puts "\n\n🚀 Starting Full Database Seeding..."
    puts "========================================================="

    Seed::UserService.run
    Seed::CompanyService.run
    Seed::TagService.run
    Seed::EmployeeGroupService.run
    Seed::EmployeeService.run
    Seed::EmployeeGroupAppointmentService.run
    Seed::RoleService.run
    Seed::PolicyService.run
    Seed::PolicyAppointmentService.run





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
