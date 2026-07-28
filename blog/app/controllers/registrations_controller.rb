class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :require_signup_enabled

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome aboard! 🎉 Account created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def require_signup_enabled
    unless ENV.fetch("ENABLE_SIGNUP", "true") == "true"
      redirect_to new_session_path, alert: "Registration is not available. Please contact an administrator."
    end
  end
end
