require 'rails_helper'

RSpec.feature "Homepage", type: :feature, js: true do
  describe "Guest (not signed in)" do
    it "shows static Sign In and Claim Free Starter Credits links" do
      visit root_path

      expect(page).to have_selector('[role="sign-in-button"]', text: "Sign In")
      expect(page).to have_selector('[role="sign-up-button"]', text: "Claim Free Starter Credits")
    end

    it "does not show Sign Out button" do
      visit root_path

      expect(page).not_to have_selector('[role="sign-out-button"]')
    end

    it "clicking Sign In goes to the sign-in page" do
      visit root_path

      click_link "Sign In"

      expect(page).to have_current_path(sign_in_path, wait: 10)
      expect(page).to have_selector('form[role="sign-in-form"]', wait: 10)
    end

    it "clicking Claim Free Starter Credits goes to the sign-up page" do
      visit root_path

      click_link "Claim Free Starter Credits", match: :first

      expect(page).to have_current_path(sign_up_path, wait: 10)
      expect(page).to have_selector('form[role="sign-up-form"]', wait: 10)
    end

    it "renders live demo console with chart and auto-increasing numbers" do
      visit root_path

      expect(page).to have_selector('[data-home--index-target="velocityChart"]')
      sales = find('[data-live="sales"]').text
      expect(sales).to match(/\$\d[\d,]*\.\d{2}/)
      # Numbers tick live — the initial value disappears without sleep (Capybara waiting)
      expect(page).to have_no_text(sales, wait: 8)
    end

    it "switching tenant tab updates console title" do
      visit root_path

      click_button "Grand Azalea Hotel PMS"

      expect(page).to have_selector("#tenant-title", text: "Grand Azalea Hotel")
    end
  end

  describe "Signed in user" do
    let(:user) { create(:user, system_role: :company_owner, password: 'Password@1234', password_confirmation: 'Password@1234') }

    before do
      sign_in(user)
    end

    it "Go to Dashboard, and New Company buttons" do
      visit root_path

      expect(page).to have_link("Go to Dashboard")
      expect(page).to have_link("New Company", wait: 10)
    end

    it "swaps to the signed-in header from the session cookie" do
      visit root_path

      expect(page).to have_link("Go to Dashboard")
      expect(page).not_to have_selector('#header-guest [role="sign-in-button"]')
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

    it "clicking Go to Dashboard navigates to companies page" do
      create(:company, user: user)

      visit root_path

      click_link "Go to Dashboard"

      expect(page).to have_current_path(%r{/companies/[^/]+/dashboards})
    end

    it "clicking New Company goes to the new company page" do
      visit root_path

      expect(page).to have_link("New Company", wait: 10)
      click_link "New Company"

      expect(page).to have_current_path(new_company_path, wait: 10)
      expect(page).to have_selector('input[name="company[name]"]', wait: 10)
      expect(page).to have_selector('select[name="company[business_type]"]')
      expect(page).to have_selector('select[name="company[country]"]')
    end

    it "cancel returns to the homepage" do
      visit new_company_path

      click_link "Cancel"

      expect(page).to have_current_path(root_path, wait: 10)
    end

    it "can create a new company via the new company page" do
      visit new_company_path

      expect(page).to have_selector('input[name="company[name]"]', wait: 10)
      fill_in "company[name]", with: "Test New Company"
      select "Retail", from: "company[business_type]"
      select "United States", from: "company[country]"

      click_button "Create Company"

      # Wait for page transition and check path
      expect(page).to have_current_path(%r{/companies/[^/]+/dashboards}, wait: 10)
      expect(page).to have_text("Company created successfully!", wait: 10)

      # Verify database record created
      expect(Company.find_by(name: "Test New Company")).to be_present
    end

    it "shows error when company name is duplicate" do
      create(:company, user: user, name: "Test Company")

      visit new_company_path

      expect(page).to have_selector('input[name="company[name]"]', wait: 10)
      fill_in "company[name]", with: "Test Company"
      select "Retail", from: "company[business_type]"
      select "United States", from: "company[country]"

      click_button "Create Company"

      # Validation failure redirects to root with an alert
      expect(page).to have_current_path(root_path, wait: 10)
      expect(page).to have_content(/already been taken|error/i)

      # Verify no duplicate was created
      expect(Company.where(name: "Test Company").count).to eq(1)
    end

    it "hides the admin dashboard link from non-admin owners" do
      visit root_path

      expect(page).to have_link("Go to Dashboard")
      expect(page).to have_selector("#header-admin-link.hidden", visible: :hidden)
    end
  end

  describe "Signed in manager employee" do
    let(:owner_user) { create(:user, :company_owner) }
    let!(:company) { create(:company, user: owner_user) }
    let(:manager_user) { create(:user) }
    let!(:employee) { create(:employee, company: company, user: manager_user) }

    before do
      sign_in(manager_user)
    end

    it "keeps Go to Dashboard but never shows New Company" do
      visit root_path

      expect(page).to have_link("Go to Dashboard", wait: 10)
      expect(page).to have_no_link("New Company")
    end

    it "bounces a direct visit and shows the alert at the very top" do
      visit new_company_path

      expect(page).to have_current_path(root_path, wait: 10)
      expect(page).to have_selector("#alert", text: "You are not authorized to perform this action.", wait: 10)

      # The flash bar is a fixed top overlay: pinned to the viewport top (y = 0)
      # and painting above the homepage's fixed header.
      alert_top = page.evaluate_script("document.querySelector('#alert').getBoundingClientRect().top")
      expect(alert_top).to be <= 1

      topmost = page.evaluate_script(<<~JS)
        (() => {
          const el = document.querySelector('#alert')
          const rect = el.getBoundingClientRect()
          const hit = document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2)
          return !!hit && !!hit.closest('#alert')
        })()
      JS
      expect(topmost).to be(true)
    end
  end

  describe "Signed in admin" do
    let(:admin) { create(:user, :admin, password: "Password@1234", password_confirmation: "Password@1234") }

    before do
      sign_in(admin)
    end

    it "reveals the admin dashboard link" do
      visit root_path

      expect(page).to have_link("Admin Dashboard", href: "/admin/companies", wait: 10)
    end

    it "hides Go to Dashboard and New Company for admins" do
      visit root_path

      expect(page).to have_link("Admin Dashboard", href: "/admin/companies", wait: 10)
      expect(page).not_to have_link("Go to Dashboard")
      expect(page).not_to have_link("New Company")
    end
  end
end
