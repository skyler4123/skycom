require "rails_helper"

RSpec.feature "Companies::Departments New", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

before do
  sign_in(owner)
  seed_full_client_cache(company: company, user: owner)
end

  scenario "renders new department form with name and type fields" do
    visit new_company_department_path(company)

    expect(page).to have_selector('input[name="department[name]"]', wait: 10)
    expect(page).to have_selector('select[name="department[business_type]"]', wait: 10)
  end

  scenario "creates department and redirects to show page" do
    visit new_company_department_path(company)

    fill_in 'department[name]', with: 'New Test Department'
    select 'Operations', from: 'department[business_type]'

    click_button "Save Department"

    expect(page).to have_content('New Test Department', wait: 10)

    department_record = Department.find_by(name: "New Test Department")
    expect(department_record).to be_present
    expect(page).to have_current_path(company_department_path(company, department_record), wait: 10)
  end

  scenario "creates department with email" do
    visit new_company_department_path(company)

    fill_in 'department[name]', with: 'Department With Email'
    fill_in 'department[email]', with: 'dept@example.com'

    click_button "Save Department"

    expect(page).to have_content('Department With Email', wait: 10)

    department_record = Department.find_by(name: "Department With Email")
    expect(department_record).to be_present
    expect(department_record.email).to eq('dept@example.com')
  end
end
