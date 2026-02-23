class SmmMonthProjectsController < ApplicationController
  before_action :set_smm_month
  before_action :set_smm_month_project, only: [ :destroy, :bonuses ]

  def create
    authorize! :create, SmmMonthProject

    month_project = @smm_month.smm_month_projects.new(smm_month_project_params)
    if month_project.save
      redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: month_project.id),
                  notice: "Project added to month."
    else
      redirect_to smm_months_path(month_id: @smm_month.id),
                  alert: month_project.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize! :destroy, @smm_month_project
    @smm_month_project.destroy
    redirect_to smm_months_path(month_id: @smm_month.id), notice: "Project removed from month."
  end

  def bonuses
    authorize! :read, @smm_month_project

    query = params[:q].to_s.strip
    project = @smm_month_project.project
    bonuses = project ? Bonus.where("bonuses.project ILIKE ?", project.name) : Bonus.none

    if query.present?
      pattern = "%#{query}%"
      bonuses = bonuses.where("bonuses.name ILIKE ? OR bonuses.code ILIKE ?", pattern, pattern)
    end

    render json: bonuses.order(created_at: :desc).limit(25).map { |bonus|
      { id: bonus.id, name: bonus.name, code: bonus.code }
    }
  end

  private

  def set_smm_month
    @smm_month = SmmMonth.find(params[:smm_month_id])
  end

  def set_smm_month_project
    @smm_month_project = @smm_month.smm_month_projects.find(params[:id])
  end

  def smm_month_project_params
    params.require(:smm_month_project).permit(:project_id)
  end
end
