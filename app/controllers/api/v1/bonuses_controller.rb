class Api::V1::BonusesController < ApplicationController
  before_action :set_bonus, only: [ :show, :update, :destroy ]

  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token

  # GET /api/v1/bonuses
  def index
    @bonuses = Bonus.includes(:bonus_rewards, :freespin_rewards, :bonus_buy_rewards,
                             :freechip_rewards, :bonus_code_rewards, :material_prize_rewards, :comp_point_rewards)

    # Apply filters
    @bonuses = apply_filters(@bonuses)

    # Pagination
    page = [ (params[:page] || 1).to_i, 1 ].max  # Ensure page is at least 1
    per_page = [ (params[:per_page] || 20).to_i, 100 ].min
    per_page = [ per_page, 1 ].max  # Ensure per_page is at least 1
    offset = [ (page - 1) * per_page, 0 ].max  # Ensure offset is not negative

    total_count = @bonuses.count
    @bonuses = @bonuses.limit(per_page).offset(offset)

    render json: {
              bonuses: @bonuses.as_json(include: bonus_includes, except: [ :currency ]),
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
    render json: @bonus.as_json(include: bonus_includes, except: [ :currency ])
  end

  # POST /api/v1/bonuses
  def create
    @bonus = Bonus.new(bonus_params)
    clean_inappropriate_fields

    if @bonus.save
      create_rewards_if_provided
      update_type_specific_attributes
      render json: @bonus.as_json(include: bonus_includes, except: [ :currency ]), status: :created
    else
      render json: { errors: @bonus.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors }, status: :unprocessable_entity unless performed?
  end

  # PATCH/PUT /api/v1/bonuses/1
  def update
    @bonus.assign_attributes(bonus_params)
    clean_inappropriate_fields

    if @bonus.save
      update_rewards_if_provided
      update_type_specific_attributes
      render json: @bonus.as_json(include: bonus_includes, except: [ :currency ])
    else
      render json: { errors: @bonus.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/bonuses/1
  def destroy
    @bonus.destroy
    head :no_content
  end



  # GET /api/v1/bonuses/by_type
  def by_type
    @bonuses = Bonus.by_event(params[:type]) if params[:type].present?
    @bonuses ||= Bonus.none

    render json: @bonuses.as_json(include: bonus_includes, except: [ :currency ])
  end

  # GET /api/v1/bonuses/active
  def active
    @bonuses = Bonus.active.available_now
                    .includes(:bonus_rewards, :freespin_rewards, :bonus_buy_rewards,
                             :freechip_rewards, :bonus_code_rewards, :material_prize_rewards, :comp_point_rewards)

    render json: @bonuses.as_json(include: bonus_includes, except: [ :currency ])
  end

  # GET /api/v1/bonuses/expired
  def expired
    @bonuses = Bonus.expired
                    .includes(:bonus_rewards, :freespin_rewards, :bonus_buy_rewards,
                             :freechip_rewards, :bonus_code_rewards, :material_prize_rewards, :comp_point_rewards)

    render json: @bonuses.as_json(include: bonus_includes, except: [ :currency ])
  end

  private

  def set_bonus
    @bonus = Bonus.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Bonus not found" }, status: :not_found
  end

  def bonus_params
    params.require(:bonus).permit(
      :name, :code, :event, :status, :minimum_deposit, :wager,
      :maximum_winnings, :wagering_strategy, :availability_start_date,
      :availability_end_date, :user_group, :tags, :country, :currency,
      :project, :dsl_tag, :created_by, :updated_by, :description,
      :no_more, :totally_no_more, currencies: [], groups: [], currency_minimum_deposits: {}
    )
  end

  def type_specific_params
    # Return empty hash since we now use reward associations instead of type-specific params
    {}
  end

  def create_rewards_if_provided
    # Create bonus reward if parameters provided
    if params[:bonus_reward].present?
      reward = @bonus.bonus_rewards.build
      reward.reward_type = "bonus"
      reward.amount = params[:bonus_reward][:amount]
      reward.percentage = params[:bonus_reward][:percentage]
      reward.config = params[:bonus_reward][:config] || {}
      reward.save
    elsif params[:bonus] && params[:bonus][:bonus_reward].present?
      reward = @bonus.bonus_rewards.build
      reward.reward_type = "bonus"
      reward.amount = params[:bonus][:bonus_reward][:amount]
      reward.percentage = params[:bonus][:bonus_reward][:percentage]
      reward.config = params[:bonus][:bonus_reward][:config] || {}
      reward.save
    end

    # Create freespin reward if parameters provided
    if params[:freespin_reward].present?
      reward = @bonus.freespin_rewards.build
      reward.spins_count = params[:freespin_reward][:spins_count]
      reward.game_restrictions = params[:freespin_reward][:game_restrictions]
      reward.config = params[:freespin_reward][:config] || {}
      reward.save
    elsif params[:bonus] && params[:bonus][:freespin_reward].present?
      reward = @bonus.freespin_rewards.build
      reward.spins_count = params[:bonus][:freespin_reward][:spins_count]
      reward.game_restrictions = params[:bonus][:freespin_reward][:game_restrictions]
      reward.config = params[:bonus][:freespin_reward][:config] || {}
      reward.save
    end
  end

  def update_rewards_if_provided
    # Update or create rewards based on provided parameters
    create_rewards_if_provided
  end

  def bonus_includes
    # Return all reward associations for JSON inclusion
    [
      :bonus_rewards, :freespin_rewards, :bonus_buy_rewards,
      :freechip_rewards, :bonus_code_rewards, :material_prize_rewards, :comp_point_rewards
    ]
  end

  def bonus_type_associations
    [
      :bonus_rewards, :freespin_rewards, :bonus_buy_rewards,
      :freechip_rewards, :bonus_code_rewards, :material_prize_rewards, :comp_point_rewards
    ]
  end

  def apply_filters(scope)
    # Filter by event type
    scope = scope.by_event(params[:type]) if params[:type].present?

    # Filter by status
    case params[:status]
    when "active"
      scope = scope.active
    when "inactive"
      scope = scope.inactive
    when "expired"
      scope = scope.expired
    end

    # Filter by project
    scope = scope.by_project(params[:project]) if params[:project].present?

    # Filter by dsl_tag
    scope = scope.by_dsl_tag(params[:dsl_tag]) if params[:dsl_tag].present?

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
      scope = scope.where("availability_start_date >= ?", params[:start_date])
    end

    if params[:end_date].present?
      scope = scope.where("availability_end_date <= ?", params[:end_date])
    end

    scope.order(created_at: :desc)
  end

  def clean_inappropriate_fields
    # Очищаем minimum_deposit для событий, которые его не используют
    non_deposit_events = %w[input_coupon manual collection groups_update scheduler]

    if non_deposit_events.include?(@bonus.event)
      @bonus.minimum_deposit = nil
      @bonus.currency_minimum_deposits = {}
    end
  end

  def update_type_specific_attributes
    # This method is called after bonus creation/update to handle type-specific attributes
    # Currently handled by reward associations, so this is a no-op
  end
end
