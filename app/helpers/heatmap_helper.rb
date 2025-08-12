module HeatmapHelper
  def heatmap_color(intensity, is_current_month = true)
    return "background-color: #f8f9fa;" unless is_current_month

    # Цветовая схема: белый → зеленый → красный
    # intensity от 0 до 1, где 1 соответствует 10+ бонусам
    case intensity
    when 0
      "background-color: #ffffff;" # Белый для нулевых значений
    when 0.01..0.2
      # Светло-зеленые оттенки (1-2 бонуса)
      "background-color: #c6e48b;"
    when 0.21..0.4
      # Средне-зеленые оттенки (3-4 бонуса)
      "background-color: #7bc96f;"
    when 0.41..0.6
      # Темно-зеленые оттенки (5-6 бонусов)
      "background-color: #239a3b;"
    when 0.61..0.8
      # Переходные зелено-красные оттенки (7-8 бонусов)
      "background-color: #d73027;"
    else
      # Красные оттенки (9-10+ бонусов)
      "background-color: #a50026;"
    end
  end

  def format_month_year(date)
    date.strftime("%B %Y")
  end

  def bonus_type_badge_class(bonus_type)
    case bonus_type
    when "deposit"
      "bg-success"
    when "input_coupon"
      "bg-primary"
    when "manual"
      "bg-warning"
    when "collection"
      "bg-info"
    when "groups_update"
      "bg-secondary"
    when "scheduler"
      "bg-dark"
    else
      "bg-light text-dark"
    end
  end
end
