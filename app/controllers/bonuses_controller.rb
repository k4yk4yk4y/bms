class BonusesController < ApplicationController
  before_action :set_bonus, only: [ :show, :edit, :update, :destroy, :preview ]

  # GET /bonuses
  def index
    @bonuses = Bonus.includes(:bonus_rewards, :freespin_rewards, :bonus_buy_rewards,
                             :freechip_rewards, :bonus_code_rewards, :material_prize_rewards, :comp_point_rewards)

    # Filter by event if specified
    @bonuses = @bonuses.by_event(params[:type] || params[:event]) if (params[:type] || params[:event]).present?

    # Filter by status if specified
    case params[:status]
    when "active"
      @bonuses = @bonuses.active
    when "inactive"
      @bonuses = @bonuses.inactive
    when "expired"
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

    # Get permanent bonus previews for current project
    @permanent_bonus_previews = Bonus.permanent_bonus_previews_for_project(params[:project])

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
      format.json { render json: @bonuses.as_json(except: [ :currency ]) }
    end
  end

  # GET /bonuses/1
  def show
    respond_to do |format|
      format.html
      format.json { render json: @bonus.as_json(include: bonus_includes, except: [ :currency ]) }
    end
  end

  # GET /bonuses/new
  def new
    @bonus = Bonus.new
    @event_type = params[:event] || params[:type] || "deposit"
    @bonus.event = @event_type
  end

  # GET /bonuses/1/edit
  def edit
  end

  # POST /bonuses
  def create
    @bonus = Bonus.new(bonus_params)

    respond_to do |format|
      if @bonus.save
        # Create multiple bonus rewards if provided
        create_multiple_bonus_rewards_if_provided
        # Create multiple freespin rewards if provided
        create_multiple_freespin_rewards_if_provided
        # Create multiple bonus_buy rewards if provided
        create_multiple_bonus_buy_rewards_if_provided
        # Create multiple comp_point rewards if provided
        create_multiple_comp_point_rewards_if_provided
        # Create multiple bonus_code rewards if provided
        create_multiple_bonus_code_rewards_if_provided
        format.html { redirect_to @bonus, notice: "Bonus was successfully created." }
        format.json { render json: @bonus, status: :created, location: @bonus }
      else
        @event_type = @bonus.event
        format.html { render :new }
        format.json { render json: @bonus.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bonuses/1
  def update
    # Debug logging
    Rails.logger.debug "Update params: #{params.inspect}"
    Rails.logger.debug "Bonus params: #{bonus_params.inspect}"
    Rails.logger.debug "Currency minimum deposits params: #{params[:bonus][:currency_minimum_deposits].inspect}"

    respond_to do |format|
      if @bonus.update(bonus_params)
        # Update or create multiple bonus rewards if provided
        update_multiple_bonus_rewards_if_provided
        # Update or create multiple freespin rewards if provided
        update_multiple_freespin_rewards_if_provided
        # Update or create multiple bonus_buy rewards if provided
        update_multiple_bonus_buy_rewards_if_provided
        # Update or create multiple comp_point rewards if provided
        update_multiple_comp_point_rewards_if_provided
        # Update or create multiple bonus_code rewards if provided
        update_multiple_bonus_code_rewards_if_provided
        format.html { redirect_to @bonus, notice: "Bonus was successfully updated." }
        format.json { render json: @bonus }
      else
        Rails.logger.debug "Bonus update failed. Errors: #{@bonus.errors.full_messages}"
        format.html { render :edit }
        format.json { render json: @bonus.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bonuses/1
  def destroy
    @bonus.destroy
    respond_to do |format|
      format.html { redirect_to bonuses_url, notice: "Bonus was successfully deleted." }
      format.json { head :no_content }
    end
  end



  # GET /bonuses/1/preview
  def preview
    render json: {
      bonus: @bonus.as_json(include: bonus_includes, except: [ :currency ]),
      preview_data: generate_preview_data
    }
  end

  # GET /bonuses/by_type
  def by_type
    event_param = params[:type] || params[:event]
    @bonuses = Bonus.by_event(event_param) if event_param.present?
    @bonuses ||= Bonus.none

    render json: @bonuses.as_json(except: [ :currency ])
  end

  # POST /bonuses/bulk_update
  def bulk_update
    bonus_ids = params[:bonus_ids] || []
    action = params[:bulk_action]

    bonuses = Bonus.where(id: bonus_ids)

    case action
    when "delete"
      bonuses.destroy_all
      message = "Bonuses were successfully deleted."
    else
      message = "Invalid bulk action."
    end

    redirect_to bonuses_path, notice: message
  end

  private

  def set_bonus
    @bonus = Bonus.find(params[:id])
  end

  def bonus_params
    params.require(:bonus).permit(
      :name, :code, :event, :status, :minimum_deposit, :wager,
      :maximum_winnings, :wagering_strategy, :availability_start_date,
      :availability_end_date, :user_group, :tags, :country, :currency,
      :project, :dsl_tag, :created_by, :updated_by, :groups, :no_more, :totally_no_more,
      :description,
      currencies: [], currency_minimum_deposits: {}
    )
  end

  def bonus_reward_params
    return {} unless params[:bonus_reward].present?

    permitted = params.require(:bonus_reward).permit(
      :bonus_type, :amount, :percentage, :wager, :max_win_fixed, :max_win_multiplier,
      :available, :code, :min, :groups, :tags, :user_can_have_duplicates, :no_more, :totally_no_more, :wagering_strategy,
      # Advanced parameters
      :range, :last_login_country, :profile_country, :current_ip_country, :emails,
      :stag, :deposit_payment_systems, :cashout_payment_systems,
      :user_can_have_disposable_email, :total_deposits, :deposits_sum, :loss_sum,
      :deposits_count, :spend_sum, :category_loss_sum, :wager_sum, :bets_count,
      :affiliates_user, :balance, :cashout, :chargeable_comp_points,
      :persistent_comp_points, :date_of_birth, :deposit, :gender, :issued_bonus,
      :registered, :social_networks, :hold_min, :hold_max,
      currencies: []
    )

    # Process max_win logic
    if params[:max_win_type] == "multiplier" && permitted[:max_win_multiplier].present?
      permitted[:max_win] = "x#{permitted[:max_win_multiplier]}"
    elsif permitted[:max_win_fixed].present?
      permitted[:max_win] = permitted[:max_win_fixed]
    end

    # Clean up temporary fields
    permitted.delete(:max_win_fixed)
    permitted.delete(:max_win_multiplier)
    permitted.delete(:bonus_type)

    permitted
  end

  def create_bonus_reward_if_provided
    reward_params = bonus_reward_params
    return if reward_params.empty? || (reward_params[:amount].blank? && reward_params[:percentage].blank?)

    reward = @bonus.bonus_rewards.build(
      reward_type: "bonus",
      amount: reward_params[:amount],
      percentage: reward_params[:percentage]
    )

    # Set all additional parameters through the config field
    config = {}
    reward_params.except(:amount, :percentage).each do |key, value|
      next if value.blank?
      config[key.to_s] = value
    end

    reward.config = config unless config.empty?
    reward.save
  end

  def update_bonus_reward_if_provided
    reward_params = bonus_reward_params
    return if reward_params.empty?

    # Find existing bonus reward or create new one
    reward = @bonus.bonus_rewards.find_by(reward_type: "bonus") ||
             @bonus.bonus_rewards.build(reward_type: "bonus")

    # Update amount/percentage
    reward.amount = reward_params[:amount] if reward_params[:amount].present?
    reward.percentage = reward_params[:percentage] if reward_params[:percentage].present?

    # Update config
    config = reward.config || {}
    reward_params.except(:amount, :percentage).each do |key, value|
      if value.blank?
        config.delete(key.to_s)
      else
        config[key.to_s] = value
      end
    end

    reward.config = config
    reward.save
  end

  def freespin_reward_params
    return {} unless params[:freespin_reward].present?

    permitted = params.require(:freespin_reward).permit(
      :spins_count, :games, :bet_level, :max_win, :no_more, :totally_no_more, :available, :code,
      :min, :groups, :tags, :stag, :wagering_strategy,
      # Advanced parameters
      :auto_activate, :duration, :activation_duration, :email_template, :range,
      :last_login_country, :profile_country, :current_ip_country, :emails,
      :deposit_payment_systems, :cashout_payment_systems, :user_can_have_duplicates,
      :user_can_have_disposable_email, :total_deposits, :deposits_sum, :loss_sum,
      :deposits_count, :spend_sum, :category_loss_sum, :wager_sum, :bets_count,
      :affiliates_user, :balance, :chargeable_comp_points, :persistent_comp_points,
      :date_of_birth, :deposit, :gender, :issued_bonus, :registered, :social_networks,
      :wager_done, :hold_min, :hold_max, :currencies, currencies: []
    )

    # Handle array fields properly
    permitted[:games] = permitted[:games].split(",").map(&:strip) if permitted[:games].is_a?(String)
    permitted[:tags] = permitted[:tags].split(",").map(&:strip) if permitted[:tags].is_a?(String)

    permitted
  end

  def create_freespin_reward_if_provided
    reward_params = freespin_reward_params
    return if reward_params.empty? || reward_params[:spins_count].blank?

    reward = @bonus.freespin_rewards.build(
      spins_count: reward_params[:spins_count]
    )

    # Set common parameters
    reward.games = reward_params[:games] if reward_params[:games].present?
    reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
    reward.max_win = reward_params[:max_win] if reward_params[:max_win].present?
    reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
    reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.min_deposit = reward_params[:min] if reward_params[:min].present?
    reward.groups = reward_params[:groups] if reward_params[:groups].present?
    reward.tags = reward_params[:tags] if reward_params[:tags].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?
    reward.wagering_strategy = reward_params[:wagering_strategy] if reward_params[:wagering_strategy].present?
    reward.currencies = reward_params[:currencies] if reward_params[:currencies].present?

    # Set advanced parameters
    config = {}
    reward.advanced_params.each do |param|
      config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present?
    end

    reward.config = config
    reward.save
  end

  def update_freespin_reward_if_provided
    reward_params = freespin_reward_params
    return if reward_params.empty?

    # Find existing freespin reward or create new one
    reward = @bonus.freespin_rewards.first || @bonus.freespin_rewards.build

    # Update spins count if provided
    reward.spins_count = reward_params[:spins_count] if reward_params[:spins_count].present?

    # Update common parameters
    reward.games = reward_params[:games] if reward_params[:games].present?
    reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
    reward.max_win = reward_params[:max_win] if reward_params[:max_win].present?
    reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
    reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.min_deposit = reward_params[:min] if reward_params[:min].present?
    reward.groups = reward_params[:groups] if reward_params[:groups].present?
    reward.tags = reward_params[:tags] if reward_params[:tags].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?
    reward.wagering_strategy = reward_params[:wagering_strategy] if reward_params[:wagering_strategy].present?
    reward.currencies = reward_params[:currencies] if reward_params[:currencies].present?

    # Update advanced parameters
    config = reward.config || {}
    reward.advanced_params.each do |param|
      if reward_params[param.to_sym].present?
        config[param] = reward_params[param.to_sym]
      end
    end

    reward.config = config
    reward.save
  end

  def multiple_bonus_rewards_params
    return [] unless params[:bonus_rewards].present?

    params[:bonus_rewards].values.map do |reward_params|
      next if reward_params.blank?

      permitted = reward_params.permit(
        :bonus_type, :amount, :percentage, :wager, :max_win_fixed, :max_win_multiplier,
        :available, :code, :min, :groups, :tags, :user_can_have_duplicates, :no_more, :totally_no_more, :wagering_strategy,
        # Advanced parameters
        :range, :last_login_country, :profile_country, :current_ip_country, :emails,
        :stag, :deposit_payment_systems, :cashout_payment_systems,
        :user_can_have_disposable_email, :total_deposits, :deposits_sum, :loss_sum,
        :deposits_count, :spend_sum, :category_loss_sum, :wager_sum, :bets_count,
        :affiliates_user, :balance, :cashout, :chargeable_comp_points,
        :persistent_comp_points, :date_of_birth, :deposit, :gender, :issued_bonus,
        :registered, :social_networks, :hold_min, :hold_max,
        :currencies, currencies: []
      )

      # Handle array fields properly
      permitted[:groups] = permitted[:groups].split(",").map(&:strip) if permitted[:groups].is_a?(String)
      permitted[:tags] = permitted[:tags].split(",").map(&:strip) if permitted[:tags].is_a?(String)
      permitted[:currencies] = permitted[:currencies].compact.reject(&:blank?) if permitted[:currencies].is_a?(Array)

      permitted
    end.compact
  end

  def multiple_freespin_rewards_params
    return [] unless params[:freespin_rewards].present?

    params[:freespin_rewards].values.map do |reward_params|
      next if reward_params.blank? || reward_params[:spins_count].blank?

      permitted = reward_params.permit(
        :spins_count, :games, :bet_level, :max_win, :no_more, :totally_no_more, :available, :code,
        :tags, :stag,
        # Advanced parameters
        :auto_activate, :duration, :activation_duration, :email_template, :range,
        :last_login_country, :profile_country, :current_ip_country, :emails,
        :deposit_payment_systems, :cashout_payment_systems, :user_can_have_duplicates,
        :user_can_have_disposable_email, :total_deposits, :deposits_sum, :loss_sum,
        :deposits_count, :spend_sum, :category_loss_sum, :wager_sum, :bets_count,
        :affiliates_user, :balance, :chargeable_comp_points, :persistent_comp_points,
        :date_of_birth, :deposit, :gender, :issued_bonus, :registered, :social_networks,
        :wager_done, :hold_min, :hold_max,
        # Currency bet levels
        currency_bet_levels: {}
      )

      # Handle array fields properly
      permitted[:games] = permitted[:games].split(",").map(&:strip) if permitted[:games].is_a?(String)
      permitted[:groups] = permitted[:groups].split(",").map(&:strip) if permitted[:groups].is_a?(String)
      permitted[:tags] = permitted[:tags].split(",").map(&:strip) if permitted[:tags].is_a?(String)
      permitted[:currencies] = permitted[:currencies].split(",").map(&:strip) if permitted[:currencies].is_a?(String)

      permitted
    end.compact
  end

  def create_multiple_bonus_rewards_if_provided
    rewards_params = multiple_bonus_rewards_params
    return if rewards_params.empty?

    rewards_params.each do |reward_params|
      next if reward_params[:amount].blank? && reward_params[:percentage].blank?

      reward = @bonus.bonus_rewards.build(
        reward_type: "bonus",
        amount: reward_params[:amount],
        percentage: reward_params[:percentage]
      )

      # Set all additional parameters through the config field
      config = {}
      reward_params.except(:amount, :percentage).each do |key, value|
        next if value.blank?
        config[key.to_s] = value
      end

      # Add common parameters from bonus
      config["currencies"] = @bonus.currencies if @bonus.currencies.present?
      config["groups"] = @bonus.groups if @bonus.groups.present?
      config["min"] = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      config["wagering_strategy"] = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      config["no_more"] = @bonus.no_more if @bonus.no_more.present?
      config["totally_no_more"] = @bonus.totally_no_more if @bonus.totally_no_more.present?

      reward.config = config unless config.empty?
      reward.save
    end
  end

  def create_multiple_freespin_rewards_if_provided
    rewards_params = multiple_freespin_rewards_params
    return if rewards_params.empty?

    rewards_params.each do |reward_params|
      reward = @bonus.freespin_rewards.build(
        spins_count: reward_params[:spins_count]
      )

      # Set common parameters
      reward.games = reward_params[:games] if reward_params[:games].present?
      reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
      reward.max_win = reward_params[:max_win] if reward_params[:max_win].present?
      reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
      reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?
      reward.available = reward_params[:available] if reward_params[:available].present?
      reward.code = reward_params[:code] if reward_params[:code].present?
      reward.tags = reward_params[:tags] if reward_params[:tags].present?
      reward.stag = reward_params[:stag] if reward_params[:stag].present?

      # Use common parameters from bonus
      reward.min_deposit = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      reward.groups = @bonus.groups if @bonus.groups.present?
      reward.wagering_strategy = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      reward.currencies = @bonus.currencies if @bonus.currencies.present?
      reward.no_more = @bonus.no_more if @bonus.no_more.present?
      reward.totally_no_more = @bonus.totally_no_more if @bonus.totally_no_more.present?

      # Set currency bet levels
      if reward_params[:currency_bet_levels].present?
        reward.currency_bet_levels = reward_params[:currency_bet_levels]
      end

      # Set advanced parameters
      config = {}
      reward.advanced_params.each do |param|
        config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present?
      end

      reward.config = config
      reward.save
    end
  end

  def update_multiple_bonus_rewards_if_provided
    # For updates, we need to handle existing rewards and new ones
    # This is a complex topic that would need careful design
    # For now, fall back to legacy method
    update_bonus_reward_if_provided
  end

  def update_multiple_freespin_rewards_if_provided
    # For updates, we need to handle existing rewards and new ones
    # This is a complex topic that would need careful design
    # For now, fall back to legacy method
    update_freespin_reward_if_provided
  end

  def bonus_buy_reward_params
    return {} unless params[:bonus_buy_reward].present?

    permitted = params.require(:bonus_buy_reward).permit(
      :buy_amount, :multiplier, :games, :bet_level, :max_win, :no_more, :totally_no_more, :available, :code,
      :min, :groups, :tags, :stag, :wagering_strategy,
      # Advanced parameters
      :auto_activate, :duration, :activation_duration, :email_template, :range,
      :last_login_country, :profile_country, :current_ip_country, :emails,
      :deposit_payment_systems, :cashout_payment_systems, :user_can_have_duplicates,
      :user_can_have_disposable_email, :total_deposits, :deposits_sum, :loss_sum,
      :deposits_count, :spend_sum, :category_loss_sum, :wager_sum, :bets_count,
      :affiliates_user, :balance, :chargeable_comp_points, :persistent_comp_points,
      :date_of_birth, :deposit, :gender, :issued_bonus, :registered, :social_networks,
      :wager_done, :hold_min, :hold_max, :currencies, currencies: [],
      # Currency bet levels
      currency_bet_levels: {}
    )

    # Handle array fields properly
    permitted[:games] = permitted[:games].split(",").map(&:strip) if permitted[:games].is_a?(String)
    permitted[:tags] = permitted[:tags].split(",").map(&:strip) if permitted[:tags].is_a?(String)

    permitted
  end

  def multiple_bonus_buy_rewards_params
    return [] unless params[:bonus_buy_rewards].present?

    params[:bonus_buy_rewards].values.map do |reward_params|
      next if reward_params.blank? || reward_params[:buy_amount].blank?

      permitted = reward_params.permit(
        :buy_amount, :multiplier, :games, :bet_level, :max_win, :no_more, :totally_no_more, :available, :code,
        :min, :groups, :tags, :stag, :wagering_strategy,
        # Advanced parameters
        :auto_activate, :duration, :activation_duration, :email_template, :range,
        :last_login_country, :profile_country, :current_ip_country, :emails,
        :deposit_payment_systems, :cashout_payment_systems, :user_can_have_duplicates,
        :user_can_have_disposable_email, :total_deposits, :deposits_sum, :loss_sum,
        :deposits_count, :spend_sum, :category_loss_sum, :wager_sum, :bets_count,
        :affiliates_user, :balance, :chargeable_comp_points, :persistent_comp_points,
        :date_of_birth, :deposit, :gender, :issued_bonus, :registered, :social_networks,
        :wager_done, :hold_min, :hold_max, :currencies, currencies: [],
        # Currency bet levels
        currency_bet_levels: {}
      )

      # Handle array fields properly
      permitted[:games] = permitted[:games].split(",").map(&:strip) if permitted[:games].is_a?(String)
      permitted[:groups] = permitted[:groups].split(",").map(&:strip) if permitted[:groups].is_a?(String)
      permitted[:tags] = permitted[:tags].split(",").map(&:strip) if permitted[:tags].is_a?(String)
      permitted[:currencies] = permitted[:currencies].split(",").map(&:strip) if permitted[:currencies].is_a?(String)

      permitted
    end.compact
  end

  def create_multiple_bonus_buy_rewards_if_provided
    rewards_params = multiple_bonus_buy_rewards_params
    return if rewards_params.empty?

    rewards_params.each do |reward_params|
      reward = @bonus.bonus_buy_rewards.build(
        buy_amount: reward_params[:buy_amount],
        multiplier: reward_params[:multiplier]
      )

      # Set common parameters
      reward.games = reward_params[:games] if reward_params[:games].present?
      reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
      reward.max_win = reward_params[:max_win] if reward_params[:max_win].present?
      reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
      reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?
      reward.available = reward_params[:available] if reward_params[:available].present?
      reward.code = reward_params[:code] if reward_params[:code].present?
      reward.tags = reward_params[:tags] if reward_params[:tags].present?
      reward.stag = reward_params[:stag] if reward_params[:stag].present?

      # Use common parameters from bonus
      reward.min_deposit = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      reward.groups = @bonus.groups if @bonus.groups.present?
      reward.wagering_strategy = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      reward.currencies = @bonus.currencies if @bonus.currencies.present?
      reward.no_more = @bonus.no_more if @bonus.no_more.present?
      reward.totally_no_more = @bonus.totally_no_more if @bonus.totally_no_more.present?

      # Set currency bet levels
      if reward_params[:currency_bet_levels].present?
        reward.currency_bet_levels = reward_params[:currency_bet_levels]
      end

      # Set advanced parameters
      config = {}
      reward.advanced_params.each do |param|
        config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present?
      end

      reward.config = config
      reward.save
    end
  end

  def update_multiple_bonus_buy_rewards_if_provided
    # For updates, we need to handle existing rewards and new ones
    # This is a complex topic that would need careful design
    # For now, fall back to legacy method
    update_bonus_buy_reward_if_provided
  end

  def create_bonus_buy_reward_if_provided
    reward_params = bonus_buy_reward_params
    return if reward_params.empty? || reward_params[:buy_amount].blank?

    reward = @bonus.bonus_buy_rewards.build(
      buy_amount: reward_params[:buy_amount],
      multiplier: reward_params[:multiplier]
    )

    # Set common parameters
    reward.games = reward_params[:games] if reward_params[:games].present?
    reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
    reward.max_win = reward_params[:max_win] if reward_params[:max_win].present?
    reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
    reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.min_deposit = reward_params[:min] if reward_params[:min].present?
    reward.groups = reward_params[:groups] if reward_params[:groups].present?
    reward.tags = reward_params[:tags] if reward_params[:tags].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?
    reward.wagering_strategy = reward_params[:wagering_strategy] if reward_params[:wagering_strategy].present?
    reward.currencies = reward_params[:currencies] if reward_params[:currencies].present?

    # Set currency bet levels
    if reward_params[:currency_bet_levels].present?
      reward.currency_bet_levels = reward_params[:currency_bet_levels]
    end

    # Set advanced parameters
    config = {}
    reward.advanced_params.each do |param|
      config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present?
    end

    reward.config = config
    reward.save
  end

  def update_bonus_buy_reward_if_provided
    reward_params = bonus_buy_reward_params
    return if reward_params.empty?

    # Find existing bonus_buy reward or create new one
    reward = @bonus.bonus_buy_rewards.first || @bonus.bonus_buy_rewards.build

    # Update buy amount and multiplier if provided
    reward.buy_amount = reward_params[:buy_amount] if reward_params[:buy_amount].present?
    reward.multiplier = reward_params[:multiplier] if reward_params[:multiplier].present?

    # Update common parameters
    reward.games = reward_params[:games] if reward_params[:games].present?
    reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
    reward.max_win = reward_params[:max_win] if reward_params[:max_win].present?
    reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
    reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.min_deposit = reward_params[:min] if reward_params[:min].present?
    reward.groups = reward_params[:groups] if reward_params[:groups].present?
    reward.tags = reward_params[:tags] if reward_params[:tags].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?
    reward.wagering_strategy = reward_params[:wagering_strategy] if reward_params[:wagering_strategy].present?
    reward.currencies = reward_params[:currencies] if reward_params[:currencies].present?

    # Update currency bet levels
    if reward_params[:currency_bet_levels].present?
      reward.currency_bet_levels = reward_params[:currency_bet_levels]
    end

    # Update advanced parameters
    config = reward.config || {}
    reward.advanced_params.each do |param|
      if reward_params[param.to_sym].present?
        config[param] = reward_params[param.to_sym]
      end
    end

    reward.config = config
    reward.save
  end

  def bonus_includes
    [
      :bonus_rewards, :freespin_rewards, :bonus_buy_rewards,
      :freechip_rewards, :bonus_code_rewards, :material_prize_rewards, :comp_point_rewards
    ]
  end

  def generate_preview_data
    {
      event: @bonus.event,
      rewards_count: @bonus.all_rewards.count,
      reward_types: @bonus.reward_types,
      has_rewards: @bonus.has_rewards?
    }
  end

  # Comp Point Rewards Parameters
  def comp_point_reward_params
    return {} unless params[:comp_point_reward].present?

    permitted = params.require(:comp_point_reward).permit(
      :issue_chargeable_award, :issue_persistent_award, :title, :config_json
    )

    permitted
  end

  def multiple_comp_point_rewards_params
    return [] unless params[:comp_point_rewards].present?

    params[:comp_point_rewards].values.map do |reward_params|
      next if reward_params.blank? || (reward_params[:issue_chargeable_award].blank? && reward_params[:issue_persistent_award].blank?)

      permitted = reward_params.permit(
        :issue_chargeable_award, :issue_persistent_award, :title, :config_json
      )

      permitted
    end.compact
  end

  # Bonus Code Rewards Parameters
  def bonus_code_reward_params
    return {} unless params[:bonus_code_reward].present?

    permitted = params.require(:bonus_code_reward).permit(
      :set_bonus_code, :title, :config_json
    )

    permitted
  end

  def multiple_bonus_code_rewards_params
    return [] unless params[:bonus_code_rewards].present?

    params[:bonus_code_rewards].values.map do |reward_params|
      next if reward_params.blank? || reward_params[:set_bonus_code].blank?

      permitted = reward_params.permit(
        :set_bonus_code, :title, :config_json
      )

      permitted
    end.compact
  end

  # Create multiple comp_point rewards if provided
  def create_multiple_comp_point_rewards_if_provided
    return unless params[:comp_point_rewards].present?

    multiple_comp_point_rewards_params.each do |reward_params|
      next if reward_params.values.all?(&:blank?)

      reward = @bonus.comp_point_rewards.build

      # Set main attributes
      reward.issue_chargeable_award = reward_params[:issue_chargeable_award]
      reward.issue_persistent_award = reward_params[:issue_persistent_award]
      reward.title = reward_params[:title]

      # Handle config_json if provided
      if reward_params[:config_json].present?
        begin
          config = JSON.parse(reward_params[:config_json])
        rescue JSON::ParserError
          config = {}
        end
      else
        config = {}
      end

      # Add common parameters from bonus
      config["currencies"] = @bonus.currencies if @bonus.currencies.present?
      config["groups"] = @bonus.groups if @bonus.groups.present?
      config["min"] = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      config["wagering_strategy"] = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      config["no_more"] = @bonus.no_more if @bonus.no_more.present?
      config["totally_no_more"] = @bonus.totally_no_more if @bonus.totally_no_more.present?

      reward.config = config unless config.empty?
      reward.save
    end
  end

  # Update multiple comp_point rewards if provided
  def update_multiple_comp_point_rewards_if_provided
    return unless params[:comp_point_rewards].present?

    # Remove existing comp_point rewards to replace them
    @bonus.comp_point_rewards.destroy_all

    multiple_comp_point_rewards_params.each do |reward_params|
      next if reward_params.values.all?(&:blank?)

      reward = @bonus.comp_point_rewards.build

      # Set main attributes
      reward.issue_chargeable_award = reward_params[:issue_chargeable_award]
      reward.issue_persistent_award = reward_params[:issue_persistent_award]
      reward.title = reward_params[:title]

      # Handle config_json if provided
      if reward_params[:config_json].present?
        begin
          config = JSON.parse(reward_params[:config_json])
        rescue JSON::ParserError
          config = {}
        end
      else
        config = {}
      end

      # Add common parameters from bonus
      config["currencies"] = @bonus.currencies if @bonus.currencies.present?
      config["groups"] = @bonus.groups if @bonus.groups.present?
      config["min"] = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      config["wagering_strategy"] = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      config["no_more"] = @bonus.no_more if @bonus.no_more.present?
      config["totally_no_more"] = @bonus.totally_no_more if @bonus.totally_no_more.present?

      reward.config = config unless config.empty?
      reward.save
    end
  end

  # Create multiple bonus_code rewards if provided
  def create_multiple_bonus_code_rewards_if_provided
    return unless params[:bonus_code_rewards].present?

    multiple_bonus_code_rewards_params.each do |reward_params|
      next if reward_params.values.all?(&:blank?)

      reward = @bonus.bonus_code_rewards.build

      # Set main attributes
      reward.set_bonus_code = reward_params[:set_bonus_code]
      reward.title = reward_params[:title]

      # Handle config_json if provided
      if reward_params[:config_json].present?
        begin
          config = JSON.parse(reward_params[:config_json])
        rescue JSON::ParserError
          config = {}
        end
      else
        config = {}
      end

      # Add common parameters from bonus
      config["currencies"] = @bonus.currencies if @bonus.currencies.present?
      config["groups"] = @bonus.groups if @bonus.groups.present?
      config["min"] = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      config["wagering_strategy"] = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      config["no_more"] = @bonus.no_more if @bonus.no_more.present?
      config["totally_no_more"] = @bonus.totally_no_more if @bonus.totally_no_more.present?

      reward.config = config unless config.empty?
      reward.save
    end
  end

  # Update multiple bonus_code rewards if provided
  def update_multiple_bonus_code_rewards_if_provided
    return unless params[:bonus_code_rewards].present?

    # Remove existing bonus_code rewards to replace them
    @bonus.bonus_code_rewards.destroy_all

    multiple_bonus_code_rewards_params.each do |reward_params|
      next if reward_params.values.all?(&:blank?)

      reward = @bonus.bonus_code_rewards.build

      # Set main attributes
      reward.set_bonus_code = reward_params[:set_bonus_code]
      reward.title = reward_params[:title]

      # Handle config_json if provided
      if reward_params[:config_json].present?
        begin
          config = JSON.parse(reward_params[:config_json])
        rescue JSON::ParserError
          config = {}
        end
      else
        config = {}
      end

      # Add common parameters from bonus
      config["currencies"] = @bonus.currencies if @bonus.currencies.present?
      config["groups"] = @bonus.groups if @bonus.groups.present?
      config["min"] = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      config["wagering_strategy"] = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      config["no_more"] = @bonus.no_more if @bonus.no_more.present?
      config["totally_no_more"] = @bonus.totally_no_more if @bonus.totally_no_more.present?

      reward.config = config unless config.empty?
      reward.save
    end
  end
end
