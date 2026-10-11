# app/controllers/registrations_controller.rb
# Serves Stimulus: registrations--new (sign-up page renders its form client-side)
# Endpoints: GET /sign_up (new) — Shell-First shell; POST /sign_up (create)

class RegistrationsController < ApplicationController
  REGISTRATION_RATE_LIMIT_MAX = 3
  REGISTRATION_RATE_LIMIT_WINDOW = 1.minute

  rate_limit to: REGISTRATION_RATE_LIMIT_MAX, within: REGISTRATION_RATE_LIMIT_WINDOW, only: :create

  skip_before_action :authenticate

  before_action :redirect_if_signed_in, only: :new

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }
      update_cookie(session: session_record, user: @user)

      send_email_verification
      redirect_to root_path, notice: "Welcome! You have signed up successfully"
    else
      redirect_to sign_up_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  private
    def redirect_if_signed_in
      redirect_to root_path if is_signed_in?
    end

    def user_params
      params.permit(:email, :password, :password_confirmation)
    end

    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
