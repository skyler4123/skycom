class SessionsController < ApplicationController
  skip_before_action :authenticate, only: %i[ new create ]
  skip_before_action :set_current_company_group_id
  before_action :set_session, only: :destroy

  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
  end

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      @session = user.sessions.create!
      # cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }
      set_sign_in_cookie(session: @session, user: user)

      redirect_to root_path, notice: "Signed in successfully"
    else
      redirect_to sign_in_path(email_hint: params[:email]), alert: "That email or password is incorrect"
    end
  end

  def destroy
    @session.destroy
    cookies.clear
    redirect_to(sessions_path, notice: "That session has been logged out")
  end

    def sign_out
    Current.session.destroy
    cookies.clear
    redirect_to(sessions_path, notice: "That session has been logged out")
  end

  private
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
