module SessionsController::OmniauthConcern
  extend ActiveSupport::Concern

  included do
    # 1. Register the method as an official callback filter first!
    before_action :concern_skip_before_action

    # 2. Now that Rails knows it exists, you can safely skip it for OmniAuth routes
    # Skip CSRF check only if you trust OmniAuth middleware's internal protection
    # skip_before_action :verify_authenticity_token, only: :create_from_omniauth
    skip_before_action :concern_skip_before_action, only: %i[ create_from_omniauth auth_failure create sign_out sign_in_for_test ]
  end

  # POST/GET /auth/:provider/callback
  def create_from_omniauth
    auth_data = request.env["omniauth.auth"]
    user = User.from_omniauth(auth_data)

    if user.persisted?
      # 1. Mirror your exact session token generation architecture
      @session = user.sessions.create!(single_access_token: SecureRandom.hex(20))
      user.update!(single_access_token: @session.single_access_token)

      # 2. Fire your CookieConcern logic to handle auth state and cache syncing
      update_cookie(
        session: @session,
        user: user
      )

      redirect_to root_path, notice: "Signed in successfully with Google"
    else
      # If validations fail, send them back to sign-in with structural context
      redirect_to sign_in_path, alert: "Could not sign you in: #{user.errors.full_messages.to_sentence}"
    end
  end

  # GET /auth/failure
  def auth_failure
    redirect_to sign_in_path, alert: "Google authentication failed or was cancelled."
  end

  def concern_skip_before_action
    authenticate
  end
end
