class UserSessionsController < ApplicationController

  def create
    @user = User.find_by(:barcode => user_session_params[:barcode])
    if @user
      session[:token] = @user.generate_token
    else
      @user = User.new
    end
  end

  def destroy
    @current_user.clean_session
    session[:token]=nil
  end

  def show
  end

  def user_session_params
    params.require(:user_session).permit(:barcode, :token)
  end
end
