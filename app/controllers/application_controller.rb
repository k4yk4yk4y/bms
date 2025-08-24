class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has()
  allow_browser versions: :modern
  
  # Include Devise helpers for all models (User and AdminUser)
  include Devise::Controllers::Helpers
  
  # Protect from CSRF attacks
  protect_from_forgery with: :exception
  
  # Devise authentication for regular app users only (admin controllers handle their own auth)
  # before_action :authenticate_user!, unless: :admin_or_devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  # CanCanCan authorization
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden, content_type: 'text/html' }
      format.html { redirect_to main_app.root_url, notice: exception.message }
      format.js   { head :forbidden, content_type: 'text/html' }
    end
  end

  private

  def admin_controller?
    controller_path.start_with?('admin/')
  end
  
  def admin_or_devise_controller?
    admin_controller? || devise_controller?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :role])
  end

  def access_denied(exception)
    redirect_to root_path, alert: exception.message
  end

  # Note: authenticate_admin_user! and current_admin_user methods
  # are automatically provided by Devise when we have 'devise_for :admin_users'

  # Active Admin unauthorized access handler
  def redirect_to_admin_login
    redirect_to new_admin_user_session_path
  end

end