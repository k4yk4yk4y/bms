class Settings::BonusTemplatesController < ApplicationController
  before_action :set_bonus_template, only: [ :show, :edit, :update, :destroy ]

  def index
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
    # Получаем базовые параметры
    permitted_params = params.require(:bonus_template).permit(
      :name, :dsl_tag, :project, :event,
      :wager, :maximum_winnings, :no_more, :totally_no_more,
      :description, currencies: [], groups: [], currency_minimum_deposits: {}
    )

    # Обрабатываем специальные поля
    if permitted_params[:currencies].is_a?(String)
      permitted_params[:currencies] = permitted_params[:currencies].split(",").map(&:strip).reject(&:blank?)
    end

    if permitted_params[:groups].is_a?(String)
      permitted_params[:groups] = permitted_params[:groups].split(",").map(&:strip).reject(&:blank?)
    end

    if permitted_params[:currency_minimum_deposits].is_a?(String) && permitted_params[:currency_minimum_deposits].present?
      begin
        permitted_params[:currency_minimum_deposits] = JSON.parse(permitted_params[:currency_minimum_deposits])
      rescue JSON::ParserError
        # Если JSON невалидный, устанавливаем пустой хэш
        permitted_params[:currency_minimum_deposits] = {}
      end
    end

    permitted_params
  end
end
