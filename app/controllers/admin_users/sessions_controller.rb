class AdminUsers::SessionsController < Devise::SessionsController
  # Use default layout for admin login

  def new
    super
  end

  def create
    Rails.logger.info "=== ADMIN LOGIN ATTEMPT ==="
    Rails.logger.info "Email: #{params[:admin_user][:email]}" if params[:admin_user]
    Rails.logger.info "AdminUser found: #{AdminUser.find_by(email: params[:admin_user][:email]).present?}" if params[:admin_user]
    super
  end

  def destroy
    super
  end

  protected

  def after_sign_in_path_for(resource)
    # После входа перенаправляем в админ-панель
    admin_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    # После выхода перенаправляем на страницу входа админ-панели
    new_admin_user_session_path
  end
end
