# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Проверяем тип пользователя и устанавливаем соответствующие права
    if user.is_a?(AdminUser)
      # AdminUser - администратор с полным доступом к Active Admin
      can :manage, :all
      can :read, ActiveAdmin::Page, name: "Dashboard"
      can :access, :all # Добавляем явное разрешение на доступ ко всем ресурсам
    elsif user.is_a?(User)
      # User - пользователь приложения с ролевыми правами
      setup_user_abilities(user)
    else
      # Гость (неаутентифицированный пользователь)
      # Никаких разрешений
    end
  end

  private

  def setup_user_abilities(user)
    case user.role
    when "admin"
      # Администратор имеет полный доступ ко всему
      can :manage, :all
      can :read, ActiveAdmin::Page, name: "Dashboard"

    when "promo_manager"
      # Промо-менеджер имеет ТОЛЬКО читательский доступ к бонусам (БЕЗ доступа к Marketing, Settings и API)
      # ЧИТАТЕЛЬСКИЙ ДОСТУП к бонусам и связанным объектам
      can :read, Bonus
      can :read, BonusReward
      can :read, FreespinReward
      can :read, BonusBuyReward
      can :read, FreechipReward
      can :read, BonusCodeReward
      can :read, MaterialPrizeReward
      can :read, CompPointReward
      can :read, User, id: user.id
      can :update, User, id: user.id
      can :read, ActiveAdmin::Page, name: "Dashboard"

      # ЗАПРЕТЫ на создание, редактирование, удаление бонусов
      cannot :create, Bonus
      cannot :update, Bonus
      cannot :destroy, Bonus
      cannot :duplicate, Bonus

      # ПОЛНЫЙ ЗАПРЕТ доступа к Marketing
      cannot :read, MarketingRequest
      cannot :manage, MarketingRequest

      # ПОЛНЫЙ ЗАПРЕТ доступа к Templates
      cannot :manage, BonusTemplate
      cannot :read, BonusTemplate

      # ПОЛНЫЙ ЗАПРЕТ доступа к Settings разделу
      cannot :access, :settings
      cannot :manage, :settings

      # ПОЛНЫЙ ЗАПРЕТ доступа к API
      cannot :access, :api
      cannot :manage, :api

    when "shift_leader"
      # Лидер смены имеет ТОЛЬКО читательский доступ ко всем разделам кроме Settings и API
      # ЧИТАТЕЛЬСКИЙ ДОСТУП к бонусам и связанным объектам
      can :read, Bonus
      can :read, BonusReward
      can :read, FreespinReward
      can :read, BonusBuyReward
      can :read, FreechipReward
      can :read, BonusCodeReward
      can :read, MaterialPrizeReward
      can :read, CompPointReward
      can :read, MarketingRequest
      can :read, User, id: user.id
      can :update, User, id: user.id
      can :read, ActiveAdmin::Page, name: "Dashboard"

      # ЗАПРЕТЫ на создание, редактирование, удаление бонусов
      cannot :create, Bonus
      cannot :update, Bonus
      cannot :destroy, Bonus
      cannot :duplicate, Bonus

      # ЗАПРЕТЫ на создание, редактирование, удаление маркетинговых заявок
      cannot :create, MarketingRequest
      cannot :update, MarketingRequest
      cannot :destroy, MarketingRequest
      cannot :activate, MarketingRequest
      cannot :reject, MarketingRequest
      cannot :transfer, MarketingRequest

      # ПОЛНЫЙ ЗАПРЕТ доступа к Templates
      cannot :manage, BonusTemplate
      cannot :read, BonusTemplate

      # ПОЛНЫЙ ЗАПРЕТ доступа к Settings разделу
      cannot :access, :settings
      cannot :manage, :settings

      # ПОЛНЫЙ ЗАПРЕТ доступа к API
      cannot :access, :api
      cannot :manage, :api

    when "marketing_manager"
      # Маркетинг-менеджер имеет доступ ТОЛЬКО к своим маркетинговым заявкам
      can [ :read, :create, :update ], MarketingRequest do |marketing_request|
        marketing_request.manager == user.email
      end
      can :read, ActiveAdmin::Page, name: "Dashboard"
      can :read, User  # Может просматривать всех пользователей
      can :update, User, id: user.id  # Может редактировать только свой профиль

      # ЗАПРЕТЫ на активацию, отклонение и удаление заявок
      cannot :activate, MarketingRequest
      cannot :reject, MarketingRequest
      cannot :destroy, MarketingRequest

      # ПОЛНЫЙ ЗАПРЕТ доступа ко всем остальным разделам
      cannot :access, :settings
      cannot :manage, :settings
      cannot :access, :api
      cannot :manage, :api
      cannot :read, Bonus     # ЗАПРЕТ на чтение бонусов
      cannot :manage, Bonus
      cannot :manage, BonusTemplate
      cannot :manage, BonusReward
      cannot :manage, FreespinReward
      cannot :manage, BonusBuyReward
      cannot :manage, FreechipReward
      cannot :manage, BonusCodeReward
      cannot :manage, MaterialPrizeReward
      cannot :manage, CompPointReward

    when "support_agent"
      # Агент поддержки имеет ограниченный доступ - ТОЛЬКО ЧТЕНИЕ

      # 1. Может просматривать бонусы и связанные объекты (только в основном разделе)
      can :read, Bonus
      can :read, BonusReward
      can :read, FreespinReward
      can :read, BonusBuyReward
      can :read, FreechipReward
      can :read, BonusCodeReward
      can :read, MaterialPrizeReward
      can :read, CompPointReward
      can :read, MarketingRequest
      can :read, ActiveAdmin::Page, name: "Dashboard"
      can :read, User, id: user.id
      can :update, User, id: user.id

      # 2. ПОЛНЫЙ ЗАПРЕТ всех действий создания, редактирования и удаления
      cannot :create, Bonus
      cannot :update, Bonus
      cannot :destroy, Bonus
      cannot :duplicate, Bonus

      cannot :manage, BonusTemplate  # Полный запрет на работу с шаблонами

      cannot :create, MarketingRequest
      cannot :update, MarketingRequest
      cannot :destroy, MarketingRequest
      cannot :activate, MarketingRequest
      cannot :reject, MarketingRequest
      cannot :transfer, MarketingRequest

      # 3. ПОЛНЫЙ ЗАПРЕТ доступа к Settings разделу
      cannot :access, :settings
      cannot :manage, :settings

      # 4. ПОЛНЫЙ ЗАПРЕТ доступа к API
      cannot :access, :api
      cannot :manage, :api

    else
      # Пользователи без определённой роли не имеют доступа
    end

    # Дополнительные правила для пользователей приложения
    if user.persisted?
      can :read, ActiveAdmin::Page, name: "Dashboard"
    end

    # Особые правила для админов среди пользователей приложения
    if user.admin?
      can :manage, User
      can :create, User
      can :destroy, User
    elsif user.marketing_manager?
      # Маркетинг менеджер уже имеет настроенные права выше
      # Добавляем только основные ограничения
      cannot :create, User
      cannot :destroy, User
    else
      # Ограничения для не-админов (кроме marketing_manager)
      cannot :create, User
      cannot :destroy, User
      cannot :manage, User
      can :read, User, id: user.id # Может читать только свой профиль
      can :update, User, id: user.id # Может обновлять только свой профиль
    end
  end
end
