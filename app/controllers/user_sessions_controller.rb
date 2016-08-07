class UserSessionsController < ApplicationController

  def create
    @user = User.find_by!(:barcode => user_session_params[:barcode])
    session[:token] = @user.generate_token
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
