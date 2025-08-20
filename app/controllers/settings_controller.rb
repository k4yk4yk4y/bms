class SettingsController < ApplicationController
  before_action :set_bonus_template, only: [ :show, :edit, :update, :destroy ]

  def templates
    @bonus_templates = BonusTemplate.all.order(:project, :dsl_tag, :name)
    @projects = BonusTemplate::PROJECTS
    @dsl_tags = BonusTemplate.distinct.pluck(:dsl_tag).sort
  end

  def show
  end

  def new
    @bonus_template = BonusTemplate.new
  end

  def create
    @bonus_template = BonusTemplate.new(bonus_template_params)

    if @bonus_template.save
      redirect_to settings_templates_path, notice: "Шаблон бонуса успешно создан."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @bonus_template.update(bonus_template_params)
      redirect_to settings_templates_path, notice: "Шаблон бонуса успешно обновлен."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bonus_template.destroy
    redirect_to settings_templates_path, notice: "Шаблон бонуса успешно удален."
  end

  private

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
