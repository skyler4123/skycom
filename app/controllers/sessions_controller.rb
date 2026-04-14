# app/controllers/sessions_controller.rb

class SessionsController < ApplicationController
  skip_before_action :set_current_request_details, only: [ :sign_out ]
  skip_before_action :set_current_session, only: [ :sign_out ]
  skip_before_action :authenticate, only: %i[ new create sign_out sign_in_for_test ]
  before_action :set_session, only: :destroy

  def index
    @sessions = current_user.sessions.order(created_at: :desc)
  end

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      @session = user.sessions.create!(single_access_token: SecureRandom.hex(20))
      user.update!(single_access_token: @session.single_access_token)

      update_cookie(
        session: @session,
        user: user
      )

      redirect_to root_path, notice: "Signed in successfully"
    else
      redirect_to sign_in_path(email_hint: params[:email]), alert: "That email or password is incorrect"
    end
  end

  def destroy
    @session.destroy
    cookies.clear
    redirect_to(root_path, notice: "That session has been logged out")
  end

  def sign_out
    current_session&.destroy
    cookies.clear
    redirect_to(root_path, notice: "That session has been logged out")
  end

  def sign_in_for_test
    unless Rails.env.test?
      render plain: "Forbidden", status: :forbidden and return
    end

    user = User.find_by(email: params[:email])
    # No password check here to make it even faster,
    # but you can keep User.authenticate_by if you want strictness.

    if user
      @session = user.sessions.create!(single_access_token: SecureRandom.hex(20))
      user.update!(single_access_token: @session.single_access_token)

      update_cookie(session: @session, user: user)

      render plain: "Signed In", status: :ok
    else
      render plain: "User Not Found", status: :not_found
    end
  end

  private
    def set_session
      @session = current_user.sessions.find(params[:id])
    end
end
