class HeatmapController < ApplicationController
  before_action :authorize_heatmap_access!
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
    @calendar_start = @start_date.beginning_of_week(:monday)
    @calendar_end = @end_date.end_of_week(:sunday)
    @comment_counts = comment_counts_by_date

    # Получаем список событий бонусов для фильтра
    @bonus_events = Bonus.distinct.pluck(:event).compact.sort

    # Навигация по месяцам
    @prev_month = @start_date.prev_month
    @next_month = @start_date.next_month
  end

  private

  def authorize_heatmap_access!
    authorize! :access, :bonuses_full
  end

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
    valid_events = Bonus::EVENT_TYPES + [ "all" ]
    valid_events.include?(bonus_event_param) ? bonus_event_param : "all"
  end

  def generate_heatmap_data
    # Покрываем все видимые ячейки календаря (включая дни соседних месяцев в сетке)
    calendar_start = @start_date.beginning_of_week(:monday)
    calendar_end = @end_date.end_of_week(:sunday)

    # Берем бонусы, период действия которых пересекается с текущей календарной сеткой
    bonuses_query = Bonus.where(
      "availability_start_date <= ? AND availability_end_date >= ?",
      calendar_end.end_of_day,
      calendar_start.beginning_of_day
    )

    # Фильтруем по событию бонуса, если выбран
    if @bonus_event != "all"
      bonuses_query = bonuses_query.where(event: @bonus_event)
    end

    # Считаем количество активных бонусов по каждому дню пересечения периода действия
    bonuses_by_date = Hash.new(0)
    bonuses_query.pluck(:availability_start_date, :availability_end_date).each do |start_at, end_at|
      next if start_at.blank? || end_at.blank?

      active_start = [ start_at.to_date, calendar_start ].max
      active_end = [ end_at.to_date, calendar_end ].min
      next if active_end < active_start

      (active_start..active_end).each do |date|
        bonuses_by_date[date] += 1
      end
    end

    # Создаем хэш с данными для каждого дня календарной сетки
    heatmap_data = {}
    # Расширенный диапазон: максимальная насыщенность с 20+ бонусов
    max_count_for_color = 20.0

    (calendar_start..calendar_end).each do |date|
      date_key = date.strftime("%Y-%m-%d")
      count = bonuses_by_date[date] || 0

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

  def comment_counts_by_date
    HeatmapComment
      .where(date: @calendar_start..@calendar_end)
      .where.not(date: nil)
      .group(:date)
      .count
      .transform_keys { |date| date.strftime("%Y-%m-%d") }
  end
end
