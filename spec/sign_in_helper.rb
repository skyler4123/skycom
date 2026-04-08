module SessionHelpers
  def sign_in(user)
    visit root_path

    # 1. Wait for the button to be ready and click it
    find('button[role="sign-in-button"]', wait: 10).click

    # 2. Use the FORM selector for 'within' instead of the controller DIV.
    # By using the string 'form[role="sign-in-form"]', Capybara will 
    # automatically re-find the form if your Stimulus controller 
    # flickers the HTML during hydration.
    within 'form[role="sign-in-form"]', wait: 10 do
      # 3. Use find().set instead of fill_in. 
      # This forces a fresh lookup of the input right before typing,
      # which prevents the StaleElement error during the 'Password' step.
      find('input[name="email"]', wait: 5).set(user.email)
      find('input[name="password"]', wait: 5).set(user.password)
      
      click_button "Sign In"
    end

    # 4. Wait for the UI to update to the signed-in state
    expect(page).to have_selector('[role="avatar"]', wait: 10)
  end
end

RSpec.configure do |config|
  config.include SessionHelpers
end
