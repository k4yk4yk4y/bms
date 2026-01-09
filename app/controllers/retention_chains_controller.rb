class RetentionChainsController < ApplicationController
  before_action :set_retention_chain, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize! :read, RetentionChain

    @projects = Project.order(:name)
    scope = RetentionChain.includes(:project, :creator)

    if params[:project_id].present?
      scope = scope.where(project_id: params[:project_id])
    end

    if params[:start_date].present? || params[:end_date].present?
      start_date = parse_date(params[:start_date])
      end_date = parse_date(params[:end_date])

      if start_date && end_date
        scope = scope.where(launch_date: start_date.beginning_of_day..end_date.end_of_day)
      elsif start_date
        scope = scope.where("launch_date >= ?", start_date.beginning_of_day)
      elsif end_date
        scope = scope.where("launch_date <= ?", end_date.end_of_day)
      end
    end

    if params[:subject].present? || params[:header].present? || params[:bonus_code].present?
      scope = scope.left_joins(retention_emails: :bonuses)
    end

    if params[:subject].present?
      scope = scope.where("retention_emails.subject ILIKE ?", "%#{params[:subject].strip}%")
    end

    if params[:header].present?
      scope = scope.where("retention_emails.header ILIKE ?", "%#{params[:header].strip}%")
    end

    if params[:bonus_code].present?
      scope = scope.where("bonuses.code ILIKE ?", "%#{params[:bonus_code].strip}%")
    end

    @retention_chains = scope.order(created_at: :desc).distinct
  end

  def show
    authorize! :read, @retention_chain
    @retention_emails = @retention_chain.retention_emails.ordered.includes(:bonuses)
  end

  def bonuses
    authorize! :read, @retention_chain
    query = params[:q].to_s.strip
    bonuses = bonuses_scope_for_chain

    if query.present?
      pattern = "%#{query}%"
      bonuses = bonuses.where("bonuses.name ILIKE ? OR bonuses.code ILIKE ?", pattern, pattern)
    end

    render json: bonuses.order(created_at: :desc).limit(25).map { |bonus|
      { id: bonus.id, name: bonus.name, code: bonus.code }
    }
  end

  def new
    authorize! :create, RetentionChain
    @retention_chain = RetentionChain.new(status: "draft")
  end

  def create
    authorize! :create, RetentionChain
    @retention_chain = RetentionChain.new(retention_chain_params)

    if @retention_chain.save
      respond_to do |format|
        format.html { redirect_to edit_retention_chain_path(@retention_chain), notice: "Retention chain created." }
        format.json { render json: autosave_payload(@retention_chain), status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { errors: @retention_chain.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def edit
    authorize! :update, @retention_chain
  end

  def update
    authorize! :update, @retention_chain

    if @retention_chain.update(retention_chain_params)
      respond_to do |format|
        format.html { redirect_to retention_chain_path(@retention_chain), notice: "Retention chain updated." }
        format.json { render json: autosave_payload(@retention_chain), status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: { errors: @retention_chain.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize! :destroy, @retention_chain
    @retention_chain.destroy
    redirect_to retention_chains_path, notice: "Retention chain deleted."
  end

  private

  def set_retention_chain
    @retention_chain = RetentionChain.find(params[:id])
  end

  def retention_chain_params
    params.require(:retention_chain).permit(:name, :project_id, :status, :launch_date)
  end

  def autosave_payload(retention_chain)
    {
      id: retention_chain.id,
      edit_url: edit_retention_chain_path(retention_chain),
      update_url: retention_chain_path(retention_chain),
      updated_at: retention_chain.updated_at
    }
  end

  def parse_date(value)
    return if value.blank?

    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    nil
  end

  def bonuses_scope_for_chain
    return Bonus.none unless @retention_chain.project

    Bonus.where(project: @retention_chain.project.name)
  end
end
