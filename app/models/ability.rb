# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Проверяем тип пользователя и устанавливаем соответствующие права
    if user.is_a?(AdminUser)
      setup_admin_abilities(user)
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
    permissions = apply_role_permissions(user)
    apply_self_profile_permissions(user, permissions["self_profile"])
  end

  def setup_admin_abilities(admin_user)
    permissions = AdminRole.normalize_permissions_hash(admin_user.admin_role&.permissions)

    permissions.each do |section_key, level|
      next if level == "none"

      case section_key
      when "dashboard"
        can :read, ActiveAdmin::Page, name: "Dashboard"
      when "bonuses"
        apply_level(level, bonuses_resources)
      when "bonus_templates"
        apply_level(level, [ BonusTemplate ])
      when "marketing_requests"
        apply_level(level, [ MarketingRequest ])
      when "bonus_audit_logs"
        apply_level(level, [ BonusAuditLog ])
      when "dsl_tags"
        apply_level(level, [ DslTag ])
      when "permanent_bonuses"
        apply_level(level, [ PermanentBonus ])
      when "projects"
        apply_level(level, [ Project ])
      when "users"
        apply_level(level, [ User ])
      when "admin_users"
        apply_level(level, [ AdminUser ])
      when "roles"
        apply_level(level, [ Role ])
      when "admin_roles"
        apply_level(level, [ AdminRole ])
      end
    end
  end

  def apply_role_permissions(user)
    permissions = Role.permissions_for(user.role)

    permissions.each do |section_key, level|
      next if level == "none"

      case section_key
      when "dashboard"
        can :read, ActiveAdmin::Page, name: "Dashboard"
      when "bonuses"
        apply_level(level, bonuses_resources)
      when "bonus_templates"
        apply_level(level, [ BonusTemplate ])
      when "marketing_requests"
        apply_marketing_permissions(user, level)
      when "bonus_audit_logs"
        apply_level(level, [ BonusAuditLog ])
      when "dsl_tags"
        apply_level(level, [ DslTag ])
      when "permanent_bonuses"
        apply_level(level, [ PermanentBonus ])
      when "users"
        apply_level(level, [ User ])
      when "retention"
        apply_level(level, [ RetentionChain, RetentionEmail, RetentionEmailBonus ])
      when "settings"
        apply_settings_permissions(level)
      when "api"
        apply_api_permissions(level)
      end
    end

    permissions
  end

  def apply_level(level, resources)
    actions = case level
    when "manage" then :manage
    when "write" then [ :read, :create, :update ]
    else :read
    end
    resources.each { |resource| can actions, resource }
  end

  def apply_marketing_permissions(user, level)
    actions = case level
    when "manage" then :manage
    when "write" then [ :read, :create, :update ]
    else :read
    end

    if user.marketing_manager?
      can actions, MarketingRequest, manager: user.email
    else
      can actions, MarketingRequest
    end
  end

  def apply_settings_permissions(level)
    if level == "manage"
      can :manage, :settings
    else
      can :access, :settings
    end
  end

  def apply_api_permissions(level)
    if level == "manage"
      can :manage, :api
    else
      can :access, :api
    end
  end

  def apply_self_profile_permissions(user, level)
    return unless user.persisted?
    return if level == "none"

    actions = case level
    when "manage", "write" then [ :read, :update ]
    else :read
    end
    can actions, User, id: user.id
  end

  def bonuses_resources
    [
      Bonus,
      BonusReward,
      FreespinReward,
      BonusBuyReward,
      FreechipReward,
      BonusCodeReward,
      MaterialPrizeReward,
      CompPointReward
    ]
  end
end
