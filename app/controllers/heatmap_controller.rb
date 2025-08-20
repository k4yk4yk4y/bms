class HeatmapController < ApplicationController
  def index
    # Получаем валидированные параметры
    @year = parse_year_param(heatmap_params[:year])
    @month = parse_month_param(heatmap_params[:month])
    @bonus_event = parse_bonus_event_param(heatmap_params[:bonus_event])

    # Создаем дату начала и конца месяца с обработкой ошибок
    begin
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
    rescue Date::Error
      # Fallback to current date if invalid parameters
      @year = Date.current.year
      @month = Date.current.month
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
    end

    # Получаем данные о бонусах для текущего месяца
    @heatmap_data = generate_heatmap_data

    # Получаем список событий бонусов для фильтра
    @bonus_events = Bonus.distinct.pluck(:event).compact.sort

    # Навигация по месяцам
    @prev_month = @start_date.prev_month
    @next_month = @start_date.next_month
  end

  private

  def heatmap_params
    params.permit(:year, :month, :bonus_event)
  end

  def parse_year_param(year_param)
    return Date.current.year if year_param.blank?
    
    year = year_param.to_i
    # Validate year is reasonable (1900-3000)
    year > 1900 && year < 3000 ? year : Date.current.year
  end

  def parse_month_param(month_param)
    return Date.current.month if month_param.blank?
    
    month = month_param.to_i
    # Validate month is between 1-12
    month >= 1 && month <= 12 ? month : Date.current.month
  end

  def parse_bonus_event_param(bonus_event_param)
    return "all" if bonus_event_param.blank?
    
    # Validate bonus_event is in the allowed list or "all"
    valid_events = Bonus::EVENT_TYPES + ["all"]
    valid_events.include?(bonus_event_param) ? bonus_event_param : "all"
  end

  def generate_heatmap_data
    # Базовый запрос бонусов
    bonuses_query = Bonus.where(
      availability_start_date: @start_date.beginning_of_day..@end_date.end_of_day
    )

    # Фильтруем по событию бонуса, если выбран
    if @bonus_event != "all"
      bonuses_query = bonuses_query.where(event: @bonus_event)
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
