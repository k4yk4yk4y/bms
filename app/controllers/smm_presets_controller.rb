class SmmPresetsController < ApplicationController
  before_action :set_smm_preset, only: [ :update, :destroy ]

  def create
    authorize! :create, SmmPreset

    @smm_preset = SmmPreset.new(smm_preset_params)
    if @smm_preset.save
      redirect_to redirect_path, notice: "Preset created."
    else
      redirect_to redirect_path, alert: @smm_preset.errors.full_messages.to_sentence
    end
  end

  def update
    authorize! :update, @smm_preset

    if @smm_preset.update(smm_preset_params)
      redirect_to redirect_path, notice: "Preset updated."
    else
      redirect_to redirect_path, alert: @smm_preset.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize! :destroy, @smm_preset
    @smm_preset.destroy
    redirect_to redirect_path, notice: "Preset deleted."
  end

  private

  def set_smm_preset
    @smm_preset = SmmPreset.find(params[:id])
  end

  def smm_preset_params
    params.require(:smm_preset).permit(
      :name,
      :project_id,
      :manager_id,
      :subject,
      :bonus_type,
      :activation_limit,
      :fs_count,
      :wager_multiplier,
      :max_win_multiplier,
      :locale,
      :group,
      currencies: []
    )
  end

  def redirect_path
    return smm_months_path(month_id: params[:return_month_id]) if params[:return_month_id].present?

    smm_months_path
  end
end
