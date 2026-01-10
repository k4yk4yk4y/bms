class SettingsController < ApplicationController
  before_action :authorize_settings_access!
  before_action :set_bonus_template, only: [ :show, :edit, :update, :destroy ]

  def templates
    authorize! :read, BonusTemplate
    @bonus_templates = BonusTemplate.all.order(:project, :dsl_tag, :name)
    @projects = Project.order(:name).pluck(:name)
    @dsl_tags = BonusTemplate.distinct.pluck(:dsl_tag).sort
  end

  def show
    authorize! :read, @bonus_template
  end

  def new
    authorize! :create, BonusTemplate
    @bonus_template = BonusTemplate.new
  end

  def create
    authorize! :create, BonusTemplate
    @bonus_template = BonusTemplate.new(bonus_template_params)

    if @bonus_template.save
      redirect_to settings_templates_path, notice: "Bonus template created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize! :update, @bonus_template
  end

  def update
    authorize! :update, @bonus_template
    if @bonus_template.update(bonus_template_params)
      redirect_to settings_templates_path, notice: "Bonus template updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize! :destroy, @bonus_template
    @bonus_template.destroy
    redirect_to settings_templates_path, notice: "Bonus template deleted successfully."
  end

  private

  def authorize_settings_access!
    authorize! :access, :settings
  end

  def set_bonus_template
    @bonus_template = BonusTemplate.find(params[:id])
  end

  def bonus_template_params
    params.require(:bonus_template).permit(
      :name, :dsl_tag, :project, :event, :currency, :minimum_deposit,
      :wager, :maximum_winnings, :no_more, :totally_no_more,
      :description, currencies: [], groups: [], currency_minimum_deposits: {}
    )
  end
end
