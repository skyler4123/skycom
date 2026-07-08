require 'rails_helper'

RSpec.feature "Sign up flash messages", type: :feature, js: true do
  let(:new_user_params) do
    {
      email: 'test_signup@example.com',
      password: 'Password@1234',
      password_confirmation: 'Password@1234'
    }
  end

  scenario "shows success flash notice on valid sign-up" do
    visit root_path
    expect(page).to have_selector('button[role="sign-up-button"]', text: "Sign Up", visible: true, wait: 10)
    click_on "Sign Up"

    within 'form[role="sign-up-form"]', wait: 10 do
      fill_in "Email", with: new_user_params[:email]
      fill_in "Password", with: new_user_params[:password]
      fill_in "Password confirmation", with: new_user_params[:password_confirmation]
      click_button "Sign Up"
    end

    expect(page).to have_selector('p#notice', text: "Welcome! You have signed up successfully", wait: 10)
  end

  scenario "shows error flash alert on mismatched password confirmation" do
    visit root_path
    expect(page).to have_selector('button[role="sign-up-button"]', text: "Sign Up", visible: true, wait: 10)
    click_on "Sign Up"

    within 'form[role="sign-up-form"]', wait: 10 do
      fill_in "Email", with: new_user_params[:email]
      fill_in "Password", with: new_user_params[:password]
      fill_in "Password confirmation", with: 'DifferentPassword@5678'
      click_button "Sign Up"
    end

    expect(page).to have_selector('p#alert', wait: 10)
    expect(page).to have_content(/doesn.*t match|confirmation/i)
  end

  scenario "stays signed in after page reload" do
    visit root_path
    expect(page).to have_selector('button[role="sign-up-button"]', text: "Sign Up", visible: true, wait: 10)
    click_on "Sign Up"

    within 'form[role="sign-up-form"]', wait: 10 do
      fill_in "Email", with: new_user_params[:email]
      fill_in "Password", with: new_user_params[:password]
      fill_in "Password confirmation", with: new_user_params[:password_confirmation]
      click_button "Sign Up"
    end

    expect(page).to have_selector('p#notice', text: "Welcome! You have signed up successfully", wait: 10)

    page.visit current_url

    expect(page).not_to have_selector('button[role="sign-in-button"]', wait: 10)
    expect(page).to have_selector('[data-controller="avatar"]', wait: 10)
  end
end
