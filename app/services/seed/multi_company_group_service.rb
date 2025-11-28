class Seed::MultiCompanyGroupService
  def initialize(owner_email:)
    @owner_email = owner_email
    @multi_company_group_owner = nil
    @company_groups = []
    @school_company_group = nil
    @hospital_company_group = nil
    @restaurant_company_group = nil
    @hotel_company_group = nil

    @school_companies = []
    @hospital_companies = []
    @restaurant_companies = []
    @hotel_companies = []

    create
  end

  def create
    @multi_company_group_owner = Seed::UserService.create(email: @owner_email)
    COMPANY_GROUP_BUSINESS_TYPES.each do |business_type, _index|
      case business_type
      when :hospital
        # Current.company_business_type = :hospital
      when :school
        seed_school(company_business_type: business_type)
      else
        # Current.company_business_type = nil
      end
    end
  end

  def seed_school(company_business_type:)
    puts "\n\n🏫 Starting School Company Group Seeding..."
    puts "========================================================="

    # --- 1. Create School Company Group ---
    puts "Creating 1 school company group..."
    @school_company_group = Seed::CompanyGroupService.create(
      user: @multi_company_group_owner,
      name: "School Company Group",
      description: "A group for multiple school companies",
      business_type: company_business_type
    )

    #--- 2. Create Schools (Companies) under the Company Group ---
    school_count = 2
    puts "Creating #{school_count} schools under the company group..."
    school_count.times do |i|
      school = Seed::CompanyService.create(
        name: "School #{i + 1}",
        description: "Description for School #{i + 1}",
        parent_company: nil,
        company_group: @school_company_group
      )
      @school_companies << school
    end
    puts "Created #{@school_companies.count} schools under the company group."
  end
end