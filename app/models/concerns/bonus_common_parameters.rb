module BonusCommonParameters
  extend ActiveSupport::Concern

  # Получаем валюты из основного бонуса
  def currencies
    bonus&.currencies || []
  end

  # Получаем группы пользователей из основного бонуса
  def groups
    bonus&.groups || []
  end

  # Получаем теги из основного бонуса
  def tags
    bonus&.tags&.split(",")&.map(&:strip)&.reject(&:blank?) || []
  end

  # Получаем минимальный депозит для указанной валюты
  def min_deposit_for_currency(currency)
    bonus&.minimum_deposit_for_currency(currency)
  end

  # Получаем минимальные депозиты по всем валютам
  def currency_minimum_deposits
    bonus&.currency_minimum_deposits || {}
  end

  # Получаем ограничения использования из основного бонуса
  def no_more
    bonus&.no_more
  end

  def totally_no_more
    bonus&.totally_no_more
  end

  # Получаем стратегию отыгрыша из основного бонуса
  def wagering_strategy
    bonus&.wagering_strategy
  end

  # Форматированные методы для отображения
  def formatted_currencies
    currencies.join(", ") if currencies.any?
  end

  def formatted_groups
    groups.join(", ") if groups.any?
  end

  def formatted_tags
    tags.join(", ") if tags.any?
  end

  def formatted_no_more
    no_more.present? ? no_more : "No limit"
  end

  def formatted_totally_no_more
    totally_no_more.present? ? "#{totally_no_more} total" : "Unlimited"
  end

  # Проверяем, есть ли ограничения по минимальным депозитам
  def has_minimum_deposit_requirements?
    bonus&.has_minimum_deposit_requirements? || false
  end
end
