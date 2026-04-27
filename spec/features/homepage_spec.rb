require 'rails_helper'

RSpec.feature "Homepage", type: :feature, js: true do
  describe "Guest (not signed in)" do
    it "shows Sign In and Sign Up buttons" do
      visit root_path

      expect(page).to have_selector('[role="sign-in-button"]', text: "Sign In")
      expect(page).to have_selector('[role="sign-up-button"]', text: "Sign Up")
    end

    it "does not show Sign Out button" do
      visit root_path

      expect(page).not_to have_selector('[role="sign-out-button"]')
    end

    it "clicking Sign In opens modal" do
      visit root_path

      click_button "Sign In"

      expect(page).to have_content("Email")
    end
  end

  describe "Signed in user" do
    let(:user) { create(:user, system_role: :company_owner, password: 'Password@1234', password_confirmation: 'Password@1234') }

    before do
      sign_in(user)
    end

    it "My Companies, and New Company buttons" do
      visit root_path

      expect(page).to have_link("My Companies")
      expect(page).to have_button("New Company")
    end

    it "Avatar" do
      visit root_path

      expect(page).to have_selector('[data-controller="avatar"]')
    end

    it "clicking Sign Out signs user out" do
      visit root_path

      find('[data-controller="avatar"]').click
      click_link "Sign Out"

      expect(page).to have_current_path(root_path)
      expect(page).to have_selector('[role="sign-in-button"]', text: "Sign In")
    end

    it "clicking My Companies navigates to companies page" do
      create(:company, user: user)

      visit root_path

      click_link "My Companies"

      expect(page).to have_current_path(%r{/companies/[^/]+/dashboards})
    end

    it "clicking New Company opens modal with form" do
      visit root_path

      click_button "New Company"

      expect(page).to have_selector('input[name="company[name]"]', wait: 10)
      expect(page).to have_selector('select[name="company[business_type]"]')
    end

    it "can create a new company via modal form" do
      visit root_path

      click_button "New Company"

      expect(page).to have_selector('input[name="company[name]"]', wait: 10)
      fill_in "company[name]", with: "Test New Company"
      select "Retail", from: "company[business_type]"

      click_button "Create Company"

      # Modal closes after success - wait for it to disappear
      expect(page).not_to have_selector('input[name="company[name]"]', wait: 10)

      # Verify database record created
      expect(Company.find_by(name: "Test New Company")).to be_present
    end
  end
end
