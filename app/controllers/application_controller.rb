class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  before_filter :set_current_user

  def record_not_found
    redirect_to :action => 'index'
  end

  def set_current_user
    @current_user = nil
    if session[:token]
      @current_user = User.find_by(:token => session[:token])
    end
  end

end
