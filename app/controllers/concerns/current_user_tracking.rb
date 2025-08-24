module CurrentUserTracking
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
  end

  private

  def set_current_user
    # Устанавливаем текущего пользователя для использования в моделях
    return if Rails.env.test? # Пропускаем в тестах

    if defined?(current_admin_user) && current_admin_user
      Thread.current[:current_user] = current_admin_user
    elsif defined?(current_user) && current_user
      Thread.current[:current_user] = current_user
    end
  rescue ArgumentError
    # В тестах Devise может не быть полностью инициализирован
    # Игнорируем ошибки аргументов
  end
end
