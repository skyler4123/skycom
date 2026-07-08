require 'rails_helper'

RSpec.feature "Sign in flash messages", type: :feature, js: true do
  let(:user) { create(:user, system_role: :company_owner, password: 'Password@1234', password_confirmation: 'Password@1234') }

  scenario "shows success flash notice on valid credentials" do
    visit root_path
    expect(page).to have_selector('button[role="sign-in-button"]', text: "Sign In", visible: true, wait: 10)
    find('button[role="sign-in-button"]', wait: 10).click

    within 'form[role="sign-in-form"]', wait: 10 do
      find('input[name="email"]', wait: 5).set(user.email)
      find('input[name="password"]', wait: 5).set(user.password)
      click_button "Sign In"
    end

    expect(page).to have_selector('p#notice', text: "Signed in successfully", wait: 10)
  end

  scenario "shows error flash alert on invalid credentials" do
    visit root_path
    expect(page).to have_selector('button[role="sign-in-button"]', text: "Sign In", visible: true, wait: 10)
    find('button[role="sign-in-button"]', wait: 10).click

    within 'form[role="sign-in-form"]', wait: 10 do
      find('input[name="email"]', wait: 5).set(user.email)
      find('input[name="password"]', wait: 5).set('wrong_password')
      click_button "Sign In"
    end

    expect(page).to have_selector('p#alert', text: "That email or password is incorrect", wait: 10)
  end

  scenario "stays signed in after page reload" do
    visit root_path
    expect(page).to have_selector('button[role="sign-in-button"]', text: "Sign In", visible: true, wait: 10)
    find('button[role="sign-in-button"]', wait: 10).click

    within 'form[role="sign-in-form"]', wait: 10 do
      find('input[name="email"]', wait: 5).set(user.email)
      find('input[name="password"]', wait: 5).set(user.password)
      click_button "Sign In"
    end

    expect(page).to have_selector('p#notice', text: "Signed in successfully", wait: 10)

    page.visit current_url

    expect(page).not_to have_selector('button[role="sign-in-button"]', wait: 10)
    expect(page).to have_selector('[data-controller="avatar"]', wait: 10)
  end
end
