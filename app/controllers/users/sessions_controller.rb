class Users::SessionsController < Devise::SessionsController
  # Отключаем регистрацию
  def new
    super
  end

  def create
    Rails.logger.info "=== LOGIN ATTEMPT ==="
    Rails.logger.info "Email: #{params[:user][:email]}" if params[:user]
    Rails.logger.info "User found: #{User.find_by(email: params[:user][:email]).present?}" if params[:user]
    Rails.logger.info "Authenticity token from form: #{params[:authenticity_token]}"
    Rails.logger.info "Session token: #{session[:_csrf_token]}"
    Rails.logger.info "Form authenticity token valid: #{form_authenticity_token == params[:authenticity_token]}"
    super
  end

  def destroy
    # Принимаем как GET, так и DELETE запросы для выхода
    sign_out(current_user) if user_signed_in?
    redirect_to new_user_session_path, notice: "Вы успешно вышли из системы."
  end

  # Отключаем восстановление пароля
  def forgot_password
    redirect_to new_user_session_path, alert: "Функция восстановления пароля недоступна. Обратитесь к администратору."
  end

  # Отключаем регистрацию
  def sign_up
    redirect_to new_user_session_path, alert: "Регистрация недоступна. Обратитесь к администратору."
  end

  protected

  def after_sign_in_path_for(resource)
    # После входа перенаправляем на страницу бонусов
    bonuses_path
  end

  def after_sign_out_path_for(resource_or_scope)
    # После выхода перенаправляем на страницу входа
    new_user_session_path
  end
end
