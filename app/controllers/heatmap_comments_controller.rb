class HeatmapCommentsController < ApplicationController
  before_action :set_date, only: [ :index, :create ]
  before_action :set_range, only: [ :index, :create ]
  before_action :set_comment, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize! :read, HeatmapComment

    @comment_days = comment_days_in_range

    if @date
      @comments = comments_for_date
      @comment = HeatmapComment.new(date: @date)
    end
  end

  def show
    authorize! :read, @comment
  end

  def edit
    authorize! :update, @comment
  end

  def create
    authorize! :create, HeatmapComment

    @comment = current_user.heatmap_comments.new(create_comment_params)
    @comment.date = @date

    unless @date
      @comment.errors.add(:date, "is invalid")
      @comment_days = comment_days_in_range
      @comments = []
      return render :index, status: :unprocessable_entity
    end

    if @comment.save
      redirect_to heatmap_comments_path(date: @comment.date, start_date: @range_start, end_date: @range_end)
    else
      @comment_days = comment_days_in_range
      @comments = comments_for_date
      render :index, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @comment

    if @comment.update(update_comment_params)
      redirect_to heatmap_comment_path(@comment)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @comment

    date = @comment.date
    @comment.destroy
    redirect_to heatmap_comments_path(date: date)
  end

  private

  def set_comment
    @comment = HeatmapComment.find(params[:id])
  end

  def set_date
    @date = parse_date(params[:date] || params.dig(:heatmap_comment, :date))
  end

  def set_range
    @range_start = parse_date(params[:start_date])
    @range_end = parse_date(params[:end_date])

    return if @range_start && @range_end

    base_date = @date || Date.current
    @range_start = base_date.beginning_of_month
    @range_end = base_date.end_of_month
  end

  def comments_for_date
    return [] unless @date

    HeatmapComment.includes(:user).where(date: @date).order(:created_at)
  end

  def comment_days_in_range
    HeatmapComment
      .where(date: @range_start..@range_end)
      .where.not(date: nil)
      .group(:date)
      .count
      .map { |date, count| [ date, count ] }
      .sort_by(&:first)
  end

  def create_comment_params
    params.require(:heatmap_comment).permit(:body, :date)
  end

  def update_comment_params
    params.require(:heatmap_comment).permit(:body)
  end

  def parse_date(value)
    return if value.blank?

    Date.iso8601(value)
  rescue Date::Error
    nil
  end
end
