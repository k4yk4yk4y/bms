class BonusesController < ApplicationController
  before_action :set_bonus, only: [:show, :edit, :update, :destroy, :preview]

  # GET /bonuses
  def index
    @bonuses = Bonus.includes(:deposit_bonus, :input_coupon_bonus, :manual_bonus, 
                             :collect_bonus, :groups_update_bonus, :scheduler_bonus)
    
    # Filter by type if specified
    @bonuses = @bonuses.by_type(params[:type]) if params[:type].present?
    
    # Filter by status if specified
    case params[:status]
    when 'active'
      @bonuses = @bonuses.active
    when 'inactive'
      @bonuses = @bonuses.inactive
    when 'expired'
      @bonuses = @bonuses.expired
    end
    
    # Filter by currency if specified
    @bonuses = @bonuses.by_currency(params[:currency]) if params[:currency].present?
    
    # Filter by country if specified
    @bonuses = @bonuses.by_country(params[:country]) if params[:country].present?
    
    # Filter by project if specified
    @bonuses = @bonuses.by_project(params[:project]) if params[:project].present?
    
    # Filter by dsl_tag if specified
    @bonuses = @bonuses.by_dsl_tag(params[:dsl_tag]) if params[:dsl_tag].present?
    
    # Search by name or code
    if params[:search].present?
      @bonuses = @bonuses.where(
        "name LIKE :search OR code LIKE :search", 
        search: "%#{params[:search]}%"
      )
    end
    
    @bonuses = @bonuses.order(id: :desc)
    
    # Pagination with 50 bonuses per page
    page = (params[:page] || 1).to_i
    per_page = 25
    offset = (page - 1) * per_page
    
    # Get total count for pagination info
    @total_bonuses = @bonuses.count
    @total_pages = (@total_bonuses.to_f / per_page).ceil
    
    @bonuses = @bonuses.limit(per_page).offset(offset)
    
    respond_to do |format|
      format.html
      format.json { render json: @bonuses.as_json(except: [:currency]) }
    end
  end

  # GET /bonuses/1
  def show
    respond_to do |format|
      format.html
      format.json { render json: @bonus.as_json(include: bonus_includes, except: [:currency]) }
    end
  end

  # GET /bonuses/new
  def new
    @bonus = Bonus.new
    @bonus_type = params[:type] || 'deposit'
    @bonus.bonus_type = @bonus_type
    build_type_specific_bonus
  end

  # GET /bonuses/1/edit
  def edit
  end

  # POST /bonuses
  def create
    @bonus = Bonus.new(bonus_params)
    clean_inappropriate_fields
    
    respond_to do |format|
      if @bonus.save
        update_type_specific_attributes
        format.html { redirect_to @bonus, notice: 'Bonus was successfully created.' }
        format.json { render json: @bonus, status: :created, location: @bonus }
      else
        build_type_specific_bonus
        format.html { render :new }
        format.json { render json: @bonus.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bonuses/1
  def update
    @bonus.assign_attributes(bonus_params)
    clean_inappropriate_fields
    
    respond_to do |format|
      if @bonus.save
        update_type_specific_attributes
        format.html { redirect_to @bonus, notice: 'Bonus was successfully updated.' }
        format.json { render json: @bonus }
      else
        format.html { render :edit }
        format.json { render json: @bonus.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bonuses/1
  def destroy
    @bonus.destroy
    respond_to do |format|
      format.html { redirect_to bonuses_url, notice: 'Bonus was successfully deleted.' }
      format.json { head :no_content }
    end
  end



  # GET /bonuses/1/preview
  def preview
    render json: {
      bonus: @bonus.as_json(include: bonus_includes, except: [:currency]),
      preview_data: generate_preview_data
    }
  end

  # GET /bonuses/by_type
  def by_type
    @bonuses = Bonus.by_type(params[:type]) if params[:type].present?
    @bonuses ||= Bonus.none
    
    render json: @bonuses.as_json(except: [:currency])
  end

  # POST /bonuses/bulk_update
  def bulk_update
    bonus_ids = params[:bonus_ids] || []
    action = params[:bulk_action]
    
    bonuses = Bonus.where(id: bonus_ids)
    
    case action
    when 'delete'
      bonuses.destroy_all
      message = 'Bonuses were successfully deleted.'
    else
      message = 'Invalid bulk action.'
    end
    
    redirect_to bonuses_path, notice: message
  end

  private

  def set_bonus
    @bonus = Bonus.find(params[:id])
  end

  def bonus_params
    params.require(:bonus).permit(
      :name, :code, :bonus_type, :status, :minimum_deposit, :wager, 
      :maximum_winnings, :wagering_strategy, :availability_start_date, 
      :availability_end_date, :user_group, :tags, :country, :currency,
      :project, :dsl_tag, :created_by, :updated_by
    )
  end

  def type_specific_params
    case @bonus.bonus_type
    when 'deposit'
      params.require(:deposit_bonus).permit(
        :deposit_amount_required, :bonus_percentage, :max_bonus_amount,
        :first_deposit_only, :recurring_eligible
      ) if params[:deposit_bonus]
    when 'input_coupon'
      params.require(:input_coupon_bonus).permit(
        :coupon_code, :usage_limit, :expires_at, :single_use
      ) if params[:input_coupon_bonus]
    when 'manual'
      params.require(:manual_bonus).permit(
        :admin_notes, :approval_required, :auto_apply, :conditions
      ) if params[:manual_bonus]
    when 'collection'
      params.require(:collect_bonus).permit(
        :collection_type, :collection_amount, :collection_frequency,
        :collection_limit
      ) if params[:collect_bonus]
    when 'groups_update'
      params.require(:groups_update_bonus).permit(
        :target_groups, :update_type, :update_parameters, :batch_size
      ) if params[:groups_update_bonus]
    when 'scheduler'
      params.require(:scheduler_bonus).permit(
        :schedule_type, :cron_expression, :next_run_at, :max_executions
      ) if params[:scheduler_bonus]
    end
  end

  def build_type_specific_bonus
    case @bonus.bonus_type
    when 'deposit'
      @bonus.build_deposit_bonus unless @bonus.deposit_bonus
    when 'input_coupon'
      @bonus.build_input_coupon_bonus unless @bonus.input_coupon_bonus
    when 'manual'
      @bonus.build_manual_bonus unless @bonus.manual_bonus
    when 'collection'
      @bonus.build_collect_bonus unless @bonus.collect_bonus
    when 'groups_update'
      @bonus.build_groups_update_bonus unless @bonus.groups_update_bonus
    when 'scheduler'
      @bonus.build_scheduler_bonus unless @bonus.scheduler_bonus
    end
  end

  def update_type_specific_attributes
    type_params = type_specific_params
    return unless type_params
    
    case @bonus.bonus_type
    when 'deposit'
      if @bonus.deposit_bonus
        @bonus.deposit_bonus.update(type_params)
      else
        @bonus.create_deposit_bonus(type_params)
      end
    when 'input_coupon'
      if @bonus.input_coupon_bonus
        @bonus.input_coupon_bonus.update(type_params)
      else
        @bonus.create_input_coupon_bonus(type_params)
      end
    when 'manual'
      if @bonus.manual_bonus
        @bonus.manual_bonus.update(type_params)
      else
        @bonus.create_manual_bonus(type_params)
      end
    when 'collection'
      if @bonus.collect_bonus
        @bonus.collect_bonus.update(type_params)
      else
        @bonus.create_collect_bonus(type_params)
      end
    when 'groups_update'
      if @bonus.groups_update_bonus
        @bonus.groups_update_bonus.update(type_params)
      else
        @bonus.create_groups_update_bonus(type_params)
      end
    when 'scheduler'
      if @bonus.scheduler_bonus
        @bonus.scheduler_bonus.update(type_params)
      else
        @bonus.create_scheduler_bonus(type_params)
      end
    end
  end

  def bonus_includes
    case @bonus.bonus_type
    when 'deposit'
      :deposit_bonus
    when 'input_coupon'
      :input_coupon_bonus
    when 'manual'
      :manual_bonus
    when 'collection'
      :collect_bonus
    when 'groups_update'
      :groups_update_bonus
    when 'scheduler'
      :scheduler_bonus
    else
      []
    end
  end

  def generate_preview_data
    case @bonus.bonus_type
    when 'deposit'
      generate_deposit_preview
    when 'input_coupon'
      generate_coupon_preview
    when 'manual'
      generate_manual_preview
    when 'collection'
      generate_collect_preview
    when 'groups_update'
      generate_groups_update_preview
    when 'scheduler'
      generate_scheduler_preview
    else
      {}
    end
  end

  def generate_deposit_preview
    return {} unless @bonus.deposit_bonus
    
    sample_deposits = [100, 250, 500, 1000]
    previews = sample_deposits.map do |amount|
      bonus_amount = @bonus.deposit_bonus.calculate_bonus_amount(amount)
      {
        deposit_amount: amount,
        bonus_amount: bonus_amount,
        total_amount: amount + bonus_amount,
        eligible: @bonus.deposit_bonus.eligible_for_deposit?(amount)
      }
    end
    
    { deposit_previews: previews }
  end

  def generate_coupon_preview
    return {} unless @bonus.input_coupon_bonus
    
    {
      coupon_code: @bonus.input_coupon_bonus.coupon_code,
      remaining_uses: @bonus.input_coupon_bonus.remaining_uses,
      expires_in_days: @bonus.input_coupon_bonus.days_until_expiry,
      available: @bonus.input_coupon_bonus.available?
    }
  end

  def generate_manual_preview
    return {} unless @bonus.manual_bonus
    
    {
      requires_approval: @bonus.manual_bonus.approval_required,
      auto_apply: @bonus.manual_bonus.auto_apply,
      conditions_count: @bonus.manual_bonus.conditions_array.size
    }
  end

  def generate_collect_preview
    return {} unless @bonus.collect_bonus
    
    {
      collection_type: @bonus.collect_bonus.collection_type,
      amount_per_collection: @bonus.collect_bonus.collection_amount,
      remaining_collections: @bonus.collect_bonus.remaining_collections,
      can_collect_today: @bonus.collect_bonus.can_collect_today?
    }
  end

  def generate_groups_update_preview
    return {} unless @bonus.groups_update_bonus
    
    {
      target_groups_count: @bonus.groups_update_bonus.target_groups_array.size,
      update_type: @bonus.groups_update_bonus.update_type,
      batch_size: @bonus.groups_update_bonus.batch_size,
      estimated_time: @bonus.groups_update_bonus.estimated_processing_time
    }
  end

  def generate_scheduler_preview
    return {} unless @bonus.scheduler_bonus
    
    {
      schedule_type: @bonus.scheduler_bonus.schedule_type,
      next_execution: @bonus.scheduler_bonus.next_execution_formatted,
      remaining_executions: @bonus.scheduler_bonus.remaining_executions,
      is_active: @bonus.scheduler_bonus.is_active?
    }
  end

  def clean_inappropriate_fields
    # Очищаем minimum_deposit для типов бонусов, которые его не используют
    non_deposit_types = %w[input_coupon manual collection groups_update scheduler deposit]
    
    if non_deposit_types.include?(@bonus.bonus_type)
      @bonus.minimum_deposit = nil
    end
  end
end
