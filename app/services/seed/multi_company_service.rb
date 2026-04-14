class Seed::MultiCompanyService
  def initialize(user:)
    Seed::RetailService.new(user: user, email: "retail1@company1.com")
    # Seed::RetailService.new(user: user, email: "company@company2.com")

    # Seed::EducationService.new(user: user)
    # Seed::HealthcareService.new(user: user)
    # Seed::ManufacturingService.new(user: user)
    # Seed::FoodBeverageService.new(user: user)
    # Seed::ServiceIndustryService.new(user: user)
    # Seed::ConstructionService.new(user: user)
    # Seed::HospitalityService.new(user: user)
    # Seed::HotelService.new(user: user)
    # Seed::RealEstateService.new(user: user)
    # Seed::NonProfitService.new(user: user)
    # Seed::GymService.new(user: user)
  end
end
