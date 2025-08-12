class HeatmapController < ApplicationController
  def index
    # Получаем валидированные параметры
    @year = heatmap_params[:year]&.to_i || Date.current.year
    @month = heatmap_params[:month]&.to_i || Date.current.month
    @bonus_type = heatmap_params[:bonus_type] || "all"

    # Создаем дату начала и конца месяца
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month

    # Получаем данные о бонусах для текущего месяца
    @heatmap_data = generate_heatmap_data

    # Получаем список типов бонусов для фильтра
    @bonus_types = Bonus.distinct.pluck(:bonus_type).compact.sort

    # Навигация по месяцам
    @prev_month = @start_date.prev_month
    @next_month = @start_date.next_month
  end

  private

  def heatmap_params
    params.permit(:year, :month, :bonus_type)
  end

  def generate_heatmap_data
    # Базовый запрос бонусов
    bonuses_query = Bonus.where(
      availability_start_date: @start_date.beginning_of_day..@end_date.end_of_day
    )

    # Фильтруем по типу бонуса, если выбран
    if @bonus_type != "all"
      bonuses_query = bonuses_query.where(bonus_type: @bonus_type)
    end

    # Группируем по дате начала и считаем количество
    bonuses_by_date = bonuses_query
      .group("DATE(availability_start_date)")
      .count

    # Создаем хэш с данными для каждого дня месяца
    heatmap_data = {}
    # Фиксированное максимальное значение для цветовой схемы
    max_count_for_color = 10.0

    (@start_date..@end_date).each do |date|
      date_key = date.strftime("%Y-%m-%d")
      count = bonuses_by_date[date_key] || 0

      # Вычисляем интенсивность (от 0 до 1) на основе фиксированного максимума
      intensity = [ count.to_f / max_count_for_color, 1.0 ].min

      heatmap_data[date_key] = {
        count: count,
        intensity: intensity,
        date: date
      }
    end

    heatmap_data
  end
end
