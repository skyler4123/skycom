require "rails_helper"

RSpec.feature "Companies::Branches New", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

before do
  sign_in(owner)
  seed_full_client_cache(company: company, user: owner)
end

  scenario "renders new branch form with name and type fields" do
    visit new_company_branch_path(company)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 10)
    expect(page).to have_selector('select[name="branch[business_type]"]', wait: 10)
  end

  scenario "creates branch and redirects to show page" do
    visit new_company_branch_path(company)

    fill_in 'branch[name]', with: 'New Test Branch'
    select 'Warehouse', from: 'branch[business_type]'

    click_button "Save Branch"

    expect(page).to have_content('New Test Branch', wait: 10)

    branch_record = Branch.find_by(name: "New Test Branch")
    expect(branch_record).to be_present
    expect(page).to have_current_path(company_branch_path(company, branch_record), wait: 10)
  end

  scenario "creates branch with phone and email" do
    visit new_company_branch_path(company)

    fill_in 'branch[name]', with: 'Branch With Contact'
    fill_in 'branch[phone_number]', with: '+84 123 456 789'
    fill_in 'branch[email]', with: 'branch@example.com'

    click_button "Save Branch"

    expect(page).to have_content('Branch With Contact', wait: 10)

    branch_record = Branch.find_by(name: "Branch With Contact")
    expect(branch_record).to be_present
    expect(branch_record.phone_number).to eq('+84 123 456 789')
    expect(branch_record.email).to eq('branch@example.com')
  end
end
