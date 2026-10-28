# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Sign In", type: :feature, js: true do
  let(:user) { create(:user) }

  scenario "renders the mobile sign-in form" do
    visit mobile_sign_in_path

    expect(page).to have_content("Skycom")
    expect(page).to have_content("Welcome back")
    expect(page).to have_field("Email")
    expect(page).to have_field("Password")
    expect(page).to have_button("Sign In")
  end

  scenario "shows and hides the password" do
    visit mobile_sign_in_path

    fill_in "Password", with: "Password@1234"
    expect(find("#password")[:type]).to eq("password")

    find("button[aria-label='Show password']").click

    expect(find("#password")[:type]).to eq("text")
  end

  scenario "signs in with valid credentials and redirects to home" do
    company = create(:company)

    visit mobile_sign_in_path

    fill_in "Email", with: company.user.email
    fill_in "Password", with: "Password@1234"
    click_button "Sign In"

    expect(page).to have_content("Signed in")
    expect(page).to have_content(company.user.name.split.first)
    expect(page).to have_current_path(mobile_company_home_path(company))
  end

  scenario "signs in with an employee and redirects to the company home" do
    company = create(:company)

    visit mobile_sign_in_path

    fill_in "Email", with: company.user.email
    fill_in "Password", with: "Password@1234"
    click_button "Sign In"

    expect(page).to have_content("Signed in")
    expect(page).to have_current_path(mobile_company_home_path(company))
    expect(page).to have_content(company.name)
  end

  scenario "shows an error and keeps the email with invalid credentials" do
    visit mobile_sign_in_path

    fill_in "Email", with: user.email
    fill_in "Password", with: "wrong_password"
    click_button "Sign In"

    expect(page).to have_content("Invalid email or password")
    expect(page).to have_field("Email", with: user.email)
  end

  scenario "redirects to home if already signed in" do
    company = create(:company)
    sign_in(company.user)

    visit mobile_sign_in_path

    expect(page).to have_content(company.user.name.split.first)
    expect(page).to have_current_path(mobile_company_home_path(company))
  end

  scenario "signs out and redirects to the sign-in page" do
    company = create(:company)
    sign_in(company.user)
    visit mobile_company_employee_path(company)

    click_button "Sign Out"

    expect(page).to have_current_path(mobile_sign_in_path)
    expect(page).to have_content("Signed out")
  end

  scenario "signs out from the company employee page" do
    company = create(:company)
    sign_in(company.user)
    visit mobile_company_employee_path(company)

    click_button "Sign Out"

    expect(page).to have_current_path(mobile_sign_in_path)
    expect(page).to have_content("Signed out")
  end
end
