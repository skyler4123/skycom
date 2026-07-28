class Mobile::SessionsController < Mobile::BaseController
  skip_before_action :authenticate, only: [ :new, :create ]

  def new
    redirect_to mobile_home_path if is_signed_in?
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      session = user.sessions.create!(single_access_token: SecureRandom.hex(20))
      user.update!(single_access_token: session.single_access_token)
      update_cookie(session: session, user: user)
      redirect_to mobile_home_path, notice: "Signed in"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    current_session&.destroy
    cookies.clear
    redirect_to mobile_sign_in_path, notice: "Signed out"
  end
end
