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
    Rails.logger.info "Updating bonus template #{@bonus_template.id} with params: #{params[:bonus_template]}"

    if @bonus_template.update(bonus_template_params)
      Rails.logger.info "Bonus template #{@bonus_template.id} updated successfully"
      redirect_to settings_templates_path, notice: "Шаблон бонуса успешно обновлен."
    else
      Rails.logger.error "Failed to update bonus template #{@bonus_template.id}: #{@bonus_template.errors.full_messages}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      if @bonus_template.destroy
        redirect_to settings_templates_path, notice: "Шаблон бонуса успешно удален."
      else
        redirect_to settings_templates_path, alert: "Не удалось удалить шаблон бонуса: #{@bonus_template.errors.full_messages.join(', ')}"
      end
    rescue => e
      Rails.logger.error "Error destroying bonus template #{@bonus_template.id}: #{e.message}"
      redirect_to settings_templates_path, alert: "Ошибка при удалении шаблона бонуса: #{e.message}"
    end
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

    Rails.logger.info "Raw permitted params: #{permitted_params}"

    # Обрабатываем специальные поля
    if permitted_params[:currencies].is_a?(String)
      permitted_params[:currencies] = permitted_params[:currencies].split(",").map(&:strip).reject(&:blank?)
    end

    if permitted_params[:groups].is_a?(String)
      permitted_params[:groups] = permitted_params[:groups].split(",").map(&:strip).reject(&:blank?)
    end

    # Обрабатываем currency_minimum_deposits
    if permitted_params[:currency_minimum_deposits].is_a?(String) && permitted_params[:currency_minimum_deposits].present?
      begin
        permitted_params[:currency_minimum_deposits] = JSON.parse(permitted_params[:currency_minimum_deposits])
      rescue JSON::ParserError
        # Если JSON невалидный, устанавливаем пустой хэш
        permitted_params[:currency_minimum_deposits] = {}
      end
    elsif permitted_params[:currency_minimum_deposits].is_a?(ActionController::Parameters)
      # Если это ActionController::Parameters (из формы), преобразуем в хэш
      permitted_params[:currency_minimum_deposits] = permitted_params[:currency_minimum_deposits].to_unsafe_h
    end

    Rails.logger.info "Processed params: #{permitted_params}"
    permitted_params
  end
end
