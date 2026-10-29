# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Notifications", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }

  scenario "shows the notifications page" do
    sign_in(user)
    visit mobile_company_notifications_path(company)

    expect(page).to have_content("Notifications")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_notifications_path(company)
    expect(page).to have_current_path(mobile_sign_in_path)
  end

  scenario "redirects an unauthorized employee to home" do
    unauthorized_user = create(:user)
    create(:employee, user: unauthorized_user, company: company)

    sign_in(unauthorized_user)
    visit mobile_company_notifications_path(company)

    expect(page).to have_current_path(mobile_company_home_path(company))
    expect(page).to have_content("not authorized")
  end
end
