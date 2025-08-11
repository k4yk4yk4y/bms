class Api::V1::BonusesController < ApplicationController
  before_action :set_bonus, only: [:show, :update, :destroy, :activate, :deactivate]
  
  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token

  # GET /api/v1/bonuses
  def index
    @bonuses = Bonus.includes(:deposit_bonus, :input_coupon_bonus, :manual_bonus, 
                             :collect_bonus, :groups_update_bonus, :scheduler_bonus)
    
    # Apply filters
    @bonuses = apply_filters(@bonuses)
    
    # Pagination
    page = (params[:page] || 1).to_i
    per_page = [(params[:per_page] || 20).to_i, 100].min
    offset = (page - 1) * per_page
    
    total_count = @bonuses.count
    @bonuses = @bonuses.limit(per_page).offset(offset)
    
    render json: {
      bonuses: @bonuses.as_json(include: bonus_type_associations),
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  # GET /api/v1/bonuses/1
  def show
    render json: @bonus.as_json(include: bonus_includes)
  end

  # POST /api/v1/bonuses
  def create
    @bonus = Bonus.new(bonus_params)
    clean_inappropriate_fields
    
    if @bonus.save
      update_type_specific_attributes
      render json: @bonus.as_json(include: bonus_includes), status: :created
    else
      render json: { errors: @bonus.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/bonuses/1
  def update
    @bonus.assign_attributes(bonus_params)
    clean_inappropriate_fields
    
    if @bonus.save
      update_type_specific_attributes
      render json: @bonus.as_json(include: bonus_includes)
    else
      render json: { errors: @bonus.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/bonuses/1
  def destroy
    @bonus.destroy
    head :no_content
  end

  # PATCH /api/v1/bonuses/1/activate
  def activate
    if @bonus.activate!
      render json: { message: 'Bonus activated successfully', bonus: @bonus }
    else
      render json: { errors: @bonus.errors }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/bonuses/1/deactivate
  def deactivate
    if @bonus.deactivate!
      render json: { message: 'Bonus deactivated successfully', bonus: @bonus }
    else
      render json: { errors: @bonus.errors }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/bonuses/by_type
  def by_type
    @bonuses = Bonus.by_type(params[:type]) if params[:type].present?
    @bonuses ||= Bonus.none
    
    render json: @bonuses.as_json(include: bonus_type_associations)
  end

  # GET /api/v1/bonuses/active
  def active
    @bonuses = Bonus.active.available_now
                    .includes(:deposit_bonus, :input_coupon_bonus, :manual_bonus, 
                             :collect_bonus, :groups_update_bonus, :scheduler_bonus)
    
    render json: @bonuses.as_json(include: bonus_type_associations)
  end

  # GET /api/v1/bonuses/expired
  def expired
    @bonuses = Bonus.expired
                    .includes(:deposit_bonus, :input_coupon_bonus, :manual_bonus, 
                             :collect_bonus, :groups_update_bonus, :scheduler_bonus)
    
    render json: @bonuses.as_json(include: bonus_type_associations)
  end

  private

  def set_bonus
    @bonus = Bonus.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Bonus not found' }, status: :not_found
  end

  def bonus_params
    params.require(:bonus).permit(
      :name, :code, :bonus_type, :status, :minimum_deposit, :wager, 
      :maximum_winnings, :wagering_strategy, :availability_start_date, 
      :availability_end_date, :user_group, :tags, :country, :currency,
      :created_by, :updated_by
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

  def update_type_specific_attributes
    type_params = type_specific_params
    return unless type_params
    
    case @bonus.bonus_type
    when 'deposit'
      @bonus.deposit_bonus.update(type_params)
    when 'input_coupon'
      @bonus.input_coupon_bonus.update(type_params)
    when 'manual'
      @bonus.manual_bonus.update(type_params)
    when 'collection'
      @bonus.collect_bonus.update(type_params)
    when 'groups_update'
      @bonus.groups_update_bonus.update(type_params)
    when 'scheduler'
      @bonus.scheduler_bonus.update(type_params)
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

  def bonus_type_associations
    [:deposit_bonus, :input_coupon_bonus, :manual_bonus, 
     :collect_bonus, :groups_update_bonus, :scheduler_bonus]
  end

  def apply_filters(scope)
    # Filter by type
    scope = scope.by_type(params[:type]) if params[:type].present?
    
    # Filter by status
    case params[:status]
    when 'active'
      scope = scope.active
    when 'inactive'
      scope = scope.inactive
    when 'expired'
      scope = scope.expired
    end
    
    # Filter by currency
    scope = scope.by_currency(params[:currency]) if params[:currency].present?
    
    # Filter by country
    scope = scope.by_country(params[:country]) if params[:country].present?
    
    # Search by name or code
    if params[:search].present?
      scope = scope.where(
        "name LIKE :search OR code LIKE :search", 
        search: "%#{params[:search]}%"
      )
    end
    
    # Date range filters
    if params[:start_date].present?
      scope = scope.where('availability_start_date >= ?', params[:start_date])
    end
    
    if params[:end_date].present?
      scope = scope.where('availability_end_date <= ?', params[:end_date])
    end
    
    scope.order(created_at: :desc)
  end

  def clean_inappropriate_fields
    # Очищаем minimum_deposit для типов бонусов, которые его не используют
    non_deposit_types = %w[input_coupon manual collection groups_update scheduler deposit]
    
    if non_deposit_types.include?(@bonus.bonus_type)
      @bonus.minimum_deposit = nil
    end
  end
end
