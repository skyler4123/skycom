require "rails_helper"

RSpec.feature "Companies::Employees Dashboard", type: :feature, js: true do
  # 1. This one line creates User, Company, and Branch using your Seed services
  let(:branch)     { create(:branch) }
  let(:company)    { branch.company }
  let(:owner)      { company.user }
  
  # 2. Seed other dependencies
  let(:department) { create(:department, company: company) }
  let(:role)       { create(:role, company: company) }
  
  # 3. Create the target employee
  let(:employee) do
    create(:employee, 
      company: company, 
      branch: branch,
      departments: [department],
      roles: [role]
    )
  end

  before do
    sign_in(owner)
  end

  describe "Index Page Loading" do
    it "renders the employee list from the JSON API" do
      debugger
      # visit companies_employees_path(company)

      # # Verify the Shell/Layout loaded
      # expect(page).to have_content("Employee Name")

      # # Verify the Stimulus controller fetched and rendered the data
      # within '[data-companies--branches--employees-target="employeesList"]' do
      #   expect(page).to have_content("Skyler Dev")
      #   expect(page).to have_content("Engineering")
      #   expect(page).to have_content("Senior Developer")
      #   expect(page).to have_content("Full time")
      # end
    end
  end

  # describe "Filtering" do
  #   let!(:other_employee) { create(:employee, company: company, name: "Part Timer", business_type: "part_time") }

  #   it "filters the list when searching by business type" do
  #     visit companies_employees_path(company)
      
  #     # Ensure both are there initially
  #     expect(page).to have_content("Skyler Dev")
  #     expect(page).to have_content("Part Timer")

  #     # Select 'Part Time' from the type dropdown
  #     select "Part Time", from: "business_type"
  #     click_button "Search"

  #     # Verify filtered results
  #     expect(page).to have_content("Part Timer")
  #     expect(page).not_to have_content("Skyler Dev")
  #   end
  # end

  # describe "Modals" do
  #   it "opens the New Employee modal when clicking Add" do
  #     visit companies_employees_path(company)
      
  #     click_button "Add"

  #     # Check for the Stimulus controller identifier in the SweetAlert2 modal
  #     expect(page).to have_selector('[data-controller="companies--employees--new-modal"]')
  #   end

  #   it "opens the Edit modal when clicking the edit action" do
  #     visit companies_employees_path(company)

  #     # Find the specific edit button for our employee
  #     find("button[data-companies--branches--employees-employee-id-param='#{employee.id}']").click

  #     expect(page).to have_selector('[data-controller="companies--employees--show-modal"]')
  #   end
  # end
end