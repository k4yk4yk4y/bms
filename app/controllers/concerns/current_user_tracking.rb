module CurrentUserTracking
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
  end

  private

  def set_current_user
    # Устанавливаем текущего пользователя для использования в моделях
    if defined?(current_admin_user) && current_admin_user
      Thread.current[:current_user] = current_admin_user
    elsif defined?(current_user) && current_user
      Thread.current[:current_user] = current_user
    end
  end
end
