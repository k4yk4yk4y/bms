module HeatmapHelper
  def heatmap_color(intensity, is_current_month = true)
    return "background-color: #f8f9fa;" unless is_current_month

    # Handle edge cases - convert to float first
    intensity = intensity.to_f rescue 0.0
    return "background-color: #ffffff;" if intensity <= 0

    # Ensure intensity is within valid range and round to avoid float precision issues
    intensity = [ intensity, 1.0 ].min
    intensity = (intensity * 1000).round / 1000.0

    # Расширенная палитра: белый -> зеленый -> оранжевый -> красный
    # intensity от 0 до 1, где 1 соответствует 20+ бонусам
    color = case
    when intensity <= 0.125 then "#eaf7df"
    when intensity <= 0.25 then "#d1efbe"
    when intensity <= 0.375 then "#a8df8e"
    when intensity <= 0.5 then "#6fc35f"
    when intensity <= 0.625 then "#2f9e44"
    when intensity <= 0.75 then "#f4a261"
    when intensity <= 0.875 then "#e76f51"
    else "#b22222"
    end

    "background-color: #{color};"
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
