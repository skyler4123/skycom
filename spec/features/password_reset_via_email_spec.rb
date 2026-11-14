require 'rails_helper'

RSpec.feature "Password reset via email", type: :feature, js: true, active_job: true do
  include ActiveJob::TestHelper
  let(:user) do
    create(:user,
           system_role: :company_owner,
           email: "reset_test@example.com",
           password: "Password@1234",
           password_confirmation: "Password@1234",
           verified: true)
  end

  before do
    ActionMailer::Base.deliveries.clear
  end

  scenario "requests a reset email and completes the reset using the emailed link" do
    visit new_identity_password_reset_path

    fill_in "Email", with: user.email
    click_button "Send password reset email"

    expect(page).to have_current_path(sign_in_path, wait: 10)
    expect(page).to have_selector("p#notice", text: "Check your email for reset instructions", wait: 10)

    perform_enqueued_jobs

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([ user.email ])
    expect(mail.subject).to eq("Reset your password")

    sid = mail.body.encoded[/sid=([A-Za-z0-9_-]+)/, 1]
    expect(sid).to be_present

    visit edit_identity_password_reset_path(sid: sid)

    fill_in "New password", with: "NewPassword@1234"
    fill_in "Confirm new password", with: "NewPassword@1234"
    click_button "Save changes"

    expect(page).to have_current_path(sign_in_path, wait: 10)
    expect(page).to have_selector("p#notice", text: "Your password was reset successfully. Please sign in", wait: 10)

    # Old password no longer works
    visit sign_in_path
    within "form[role='sign-in-form']", wait: 10 do
      find("input[name='email']", wait: 5).set(user.email)
      find("input[name='password']", wait: 5).set("Password@1234")
      click_button "Sign In"
    end
    expect(page).to have_current_path(sign_in_path, wait: 10)
    expect(page).to have_selector("p#alert", wait: 10)

    # Sign in with the new password works
    visit sign_in_path
    within "form[role='sign-in-form']", wait: 10 do
      find('input[name="email"]', wait: 5).set(user.email)
      find('input[name="password"]', wait: 5).set("NewPassword@1234")
      click_button "Sign In"
    end
    expect(page).to have_selector("[data-controller='avatar']", wait: 10)
  end

  scenario "does not send an email for an unverified user" do
    unverified = create(:user,
                        system_role: :company_owner,
                        email: "unverified_reset@example.com",
                        password: "Password@1234",
                        password_confirmation: "Password@1234",
                        verified: false)

    visit new_identity_password_reset_path

    fill_in "Email", with: unverified.email
    click_button "Send password reset email"

    expect(page).to have_current_path(new_identity_password_reset_path, wait: 10)
    expect(page).to have_selector("p#alert", text: "You can't reset your password until you verify your email", wait: 10)

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  scenario "does not send an email for an unknown email address" do
    visit new_identity_password_reset_path

    fill_in "Email", with: "nobody_reset@example.com"
    click_button "Send password reset email"

    expect(page).to have_current_path(new_identity_password_reset_path, wait: 10)
    expect(page).to have_selector("p#alert", text: "You can't reset your password until you verify your email", wait: 10)

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  scenario "rejects an invalid reset link" do
    visit edit_identity_password_reset_path(sid: "invalid-token")

    expect(page).to have_current_path(new_identity_password_reset_path, wait: 10)
    expect(page).to have_selector("p#alert", text: "That password reset link is invalid", wait: 10)
  end

  scenario "rejects mismatched password confirmation" do
    visit new_identity_password_reset_path
    fill_in "Email", with: user.email
    click_button "Send password reset email"

    expect(page).to have_selector("p#notice", text: "Check your email for reset instructions", wait: 10)

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    mail = ActionMailer::Base.deliveries.last
    sid = mail.body.encoded[/sid=([A-Za-z0-9_-]+)/, 1]

    visit edit_identity_password_reset_path(sid: sid)

    fill_in "New password", with: "NewPassword@1234"
    fill_in "Confirm new password", with: "DifferentPassword@1234"
    click_button "Save changes"

    expect(page).not_to have_current_path(sign_in_path, wait: 10)
    expect(page).to have_current_path(edit_identity_password_reset_path(sid: sid), wait: 10)
  end
end
