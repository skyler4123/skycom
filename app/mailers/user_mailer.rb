class UserMailer < ApplicationMailer
  def password_reset
    @user = params[:user]
    @signed_id = @user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "Reset your password"
  end

  def email_verification
    @user = params[:user]
    @signed_id = @user.generate_token_for(:email_verification)

    mail to: @user.email, subject: "Verify your email"
  end

  def passwordless
    @user = params[:user]
    @signed_id = @user.sign_in_tokens.create.signed_id(expires_in: SIGN_IN_TOKEN_EXPIRY)

    mail to: @user.email, subject: "Your sign in link"
  end

  def invitation_instructions
    @user = params[:user]
    @signed_id = @user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "Invitation instructions"
  end
end
