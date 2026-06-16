# config/initializers/omniauth.rb

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV["GOOGLE_CLIENT_ID"],
           ENV["GOOGLE_CLIENT_SECRET"],
           scope: "email,profile",
           prompt: "select_account",
           image_aspect_ratio: "square"
end

# Enable Test Mode for Development and Test environments
if Rails.env.development? || Rails.env.test?
  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: "google_oauth2",
    uid: "google-mock-123456789",
    info: {
      email: "manager_1_retail_branch_1@company1.com",
      name: "Manager One",
      first_name: "Manager",
      last_name: "One",
      image: "https://avatar.iran.liara.run/public/30"
    }
  })
end
