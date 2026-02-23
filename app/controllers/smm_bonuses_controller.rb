class SmmBonusesController < ApplicationController
  before_action :set_smm_month
  before_action :set_smm_bonus, only: [ :update, :destroy ]

  def create
    authorize! :create, SmmBonus

    @smm_bonus = SmmBonus.new(smm_bonus_params)
    if @smm_bonus.save
      redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: @smm_bonus.smm_month_project_id),
                  notice: "Bonus added."
    else
      redirect_to smm_months_path(month_id: @smm_month.id), alert: @smm_bonus.errors.full_messages.to_sentence
    end
  end

  def update
    authorize! :update, @smm_bonus

    if @smm_bonus.update(smm_bonus_params)
      redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: @smm_bonus.smm_month_project_id),
                  notice: "Bonus updated."
    else
      redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: @smm_bonus.smm_month_project_id),
                  alert: @smm_bonus.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize! :destroy, @smm_bonus
    month_project_id = @smm_bonus.smm_month_project_id
    @smm_bonus.destroy
    redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: month_project_id),
                notice: "Bonus deleted."
  end

  def batch_create
    authorize! :create, SmmBonus

    if params[:smm_preset_id].blank?
      return redirect_to smm_months_path(month_id: @smm_month.id), alert: "Select a preset first."
    end

    preset = SmmPreset.find(params[:smm_preset_id])
    month_project = @smm_month.smm_month_projects.find(params[:smm_month_project_id])

    unless preset.project_id == month_project.project_id
      return redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: month_project.id),
                         alert: "Preset project does not match the selected month project."
    end

    rows = params.fetch(:rows, []).map { |row| row.to_unsafe_h }
    created = 0

    if rows.empty?
      return redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: month_project.id),
                         alert: "Generate rows before creating bonuses."
    end

    ActiveRecord::Base.transaction do
      rows.each do |row|
        attrs = build_bonus_from_preset(preset, row)
        month_project.smm_bonuses.create!(attrs)
        created += 1
      end
    end

    redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: month_project.id),
                notice: "#{created} bonuses created."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to smm_months_path(month_id: @smm_month.id, month_project_id: month_project.id),
                alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_smm_month
    @smm_month = SmmMonth.find(params[:smm_month_id])
  end

  def set_smm_bonus
    @smm_bonus = @smm_month.smm_bonuses.find(params[:id])
  end

  def smm_bonus_params
    params.require(:smm_bonus).permit(
      :smm_month_project_id,
      :smm_preset_id,
      :bonus_id,
      :manager_id,
      :status,
      :code,
      :deposit,
      :activation_limit,
      :game,
      :fs_count,
      :bet_value,
      :wager_multiplier,
      :max_win_multiplier,
      :group,
      :bonus_type,
      :subject,
      :locale,
      currencies: []
    )
  end

  def build_bonus_from_preset(preset, row)
    {
      smm_preset_id: preset.id,
      manager_id: preset.manager_id,
      bonus_type: preset.bonus_type,
      subject: preset.subject,
      activation_limit: preset.activation_limit,
      fs_count: row["fs_count"].presence || preset.fs_count,
      wager_multiplier: preset.wager_multiplier,
      max_win_multiplier: preset.max_win_multiplier,
      locale: preset.locale,
      group: preset.group,
      currencies: preset.currencies,
      status: "draft",
      code: row["code"].presence,
      game: row["game"].presence,
      bet_value: row["bet_value"].presence,
      deposit: row["deposit"].presence
    }
  end
end
