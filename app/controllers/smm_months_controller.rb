class SmmMonthsController < ApplicationController
  before_action :set_smm_month, only: [ :destroy, :copy ]

  def index
    authorize! :read, SmmMonth

    @smm_months = SmmMonth.ordered.includes(smm_month_projects: :project)
    @current_month = select_current_month(@smm_months)

    if @current_month
      @month_projects = @current_month.smm_month_projects.joins(:project).includes(:project).order("projects.name")
      @current_month_project = select_current_month_project(@month_projects)
    else
      @month_projects = []
      @current_month_project = nil
    end

    @smm_bonuses = if @current_month_project
      @current_month_project.smm_bonuses.includes(:bonus, :smm_preset).ordered
    else
      SmmBonus.none
    end

    @projects = Project.order(:name)
    @available_projects = if @current_month
      @projects.where.not(id: @current_month.projects.select(:id))
    else
      @projects
    end

    @smm_presets = if @current_month_project
      SmmPreset.for_project(@current_month_project.project_id).ordered
    else
      SmmPreset.none
    end

    @new_preset = SmmPreset.new(project: @current_month_project&.project)
    @new_bonus = SmmBonus.new(status: "draft")

    @managers = User.order(:email)
    @currencies_by_project = Project.order(:name).each_with_object({}) do |project, map|
      map[project.id] = project.currencies
    end
  end

  def create
    authorize! :create, SmmMonth

    starts_on = parse_month(params.dig(:smm_month, :month))
    @smm_month = SmmMonth.new(
      name: params.dig(:smm_month, :name).presence || formatted_month_name(starts_on),
      starts_on: starts_on
    )

    if @smm_month.save
      seed_projects_for(@smm_month) if params.dig(:smm_month, :seed_all_projects) == "1"
      redirect_to smm_months_path(month_id: @smm_month.id), notice: "SMM month created."
    else
      redirect_to smm_months_path, alert: @smm_month.errors.full_messages.to_sentence
    end
  end

  def copy
    authorize! :create, SmmMonth

    starts_on = parse_month(params.dig(:smm_month, :month))
    new_month = SmmMonth.new(
      name: params.dig(:smm_month, :name).presence || formatted_month_name(starts_on),
      starts_on: starts_on
    )

    if new_month.valid?
      ActiveRecord::Base.transaction do
        new_month.save!
        copy_from_month(@smm_month, new_month)
      end
      redirect_to smm_months_path(month_id: new_month.id), notice: "SMM month copied."
    else
      redirect_to smm_months_path(month_id: @smm_month.id), alert: new_month.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize! :destroy, @smm_month
    @smm_month.destroy
    redirect_to smm_months_path, notice: "SMM month deleted."
  end

  private

  def set_smm_month
    @smm_month = SmmMonth.find(params[:id])
  end

  def select_current_month(months)
    return months.find { |month| month.id == params[:month_id].to_i } if params[:month_id].present?

    months.first
  end

  def select_current_month_project(month_projects)
    if params[:month_project_id].present?
      selected = month_projects.find { |project| project.id == params[:month_project_id].to_i }
      return selected if selected
    end

    month_projects.first
  end

  def seed_projects_for(smm_month)
    Project.order(:name).find_each do |project|
      smm_month.smm_month_projects.create!(project: project)
    end
  end

  def copy_from_month(source_month, target_month)
    source_month.smm_month_projects.includes(:smm_bonuses, :project).find_each do |month_project|
      target_project = target_month.smm_month_projects.create!(project: month_project.project)
      month_project.smm_bonuses.find_each do |bonus|
        target_project.smm_bonuses.create!(bonus.duplicate_attributes)
      end
    end
  end

  def parse_month(value)
    return if value.blank?

    Date.strptime(value, "%Y-%m")
  rescue ArgumentError
    nil
  end

  def formatted_month_name(date)
    return "New month" unless date

    date.strftime("%B %Y")
  end
end
