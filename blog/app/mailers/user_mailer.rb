class UserMailer < ApplicationMailer
  def welcome
    @user = params[:user]
    mail(to: @user.email_address, subject: "Welcome to Rails8 App on GCP!")
  end
end
