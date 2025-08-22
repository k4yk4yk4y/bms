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
    @bonuses = @bonuses.by_currency(params[:currency] || params[:currencies]&.first) if (params[:currency] || params[:currencies]).present?

    # Filter by country if specified
    @bonuses = @bonuses.by_country(params[:country]) if params[:country].present?

    # Filter by project if specified
    @bonuses = @bonuses.by_project(params[:project]) if params[:project].present?

    # Filter by dsl_tag if specified
    @bonuses = @bonuses.by_dsl_tag(params[:dsl_tag]) if params[:dsl_tag].present?

    # Search by name or code
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @bonuses = @bonuses.where(
        "LOWER(name) LIKE LOWER(?) OR LOWER(code) LIKE LOWER(?)",
        search_term, search_term
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

    # Apply template if template_id is provided
    if params[:template_id].present?
      begin
        template = BonusTemplate.find(params[:template_id])
        template.apply_to_bonus(@bonus)
      rescue ActiveRecord::RecordNotFound
        # Template not found, continue without template
      end
    end

    # Set event type from params or template, with fallback to deposit
    @event_type = params[:event] || params[:type] || @bonus.event || "deposit"
    @bonus.event = @event_type
  end

  # GET /bonuses/1/edit
  def edit
  end

  # POST /bonuses
  def create
    Rails.logger.debug "CREATE METHOD CALLED with params: #{params.inspect}"

    @bonus = Bonus.new(bonus_params)
    Rails.logger.debug "Bonus created with params: #{bonus_params.inspect}"
    Rails.logger.debug "Bonus valid: #{@bonus.valid?}"
    Rails.logger.debug "Bonus errors: #{@bonus.errors.full_messages}"

    # Set currency from currencies array if needed
    if @bonus.currencies.present?
      # Filter out blank currencies
      valid_currencies = @bonus.currencies.reject(&:blank?)
      # No need to set currency field as it was removed
    end

    # Validate freespin rewards before saving bonus
    freespin_reward_params = self.freespin_reward_params
    Rails.logger.debug "Freespin reward params: #{freespin_reward_params.inspect}"
    if freespin_reward_params.present?
      # Check if spins_count is valid (must be present and greater than 0)
      spins_count = freespin_reward_params[:spins_count]
      Rails.logger.debug "Checking spins_count: #{spins_count} (type: #{spins_count.class})"
      if spins_count.blank? || spins_count.to_i <= 0
        Rails.logger.debug "Adding validation error for spins_count"
        @bonus.errors.add(:base, "Spins count must be greater than 0")
        # Don't save the bonus if validation fails
        respond_to do |format|
          @event_type = @bonus.event
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @bonus.errors, status: :unprocessable_entity }
        end
        return
      end
    end

    respond_to do |format|
      if @bonus.errors.empty? && @bonus.save

        # Create bonus rewards if provided (singular or multiple)
        create_bonus_reward_if_provided
        create_multiple_bonus_rewards_if_provided
        # Create freespin rewards if provided (singular or multiple) - only one should be called
        if params[:freespin_rewards].present? || params.dig(:bonus, :freespin_rewards).present?
          create_multiple_freespin_rewards_if_provided
        elsif params[:freespin_reward].present? || params.dig(:bonus, :freespin_reward).present?
          create_freespin_reward_if_provided
        end
        # Create multiple bonus_buy rewards if provided
        if params[:bonus_buy_rewards].present? || params.dig(:bonus, :bonus_buy_rewards).present?
          create_multiple_bonus_buy_rewards_if_provided
        end
        # Create comp_point rewards if provided (singular or multiple)
        if params[:comp_point_rewards].present? || params.dig(:bonus, :comp_point_rewards).present?
          create_multiple_comp_point_rewards_if_provided
        elsif params[:comp_point_reward].present? || params.dig(:bonus, :comp_point_reward).present?
          create_comp_point_reward_if_provided
        end
        # Create multiple bonus_code rewards if provided
        if params[:bonus_code_rewards].present? || params.dig(:bonus, :bonus_code_rewards).present?
          create_multiple_bonus_code_rewards_if_provided
        end
        # Create multiple freechip rewards if provided
        if params[:freechip_rewards].present? || params.dig(:bonus, :freechip_rewards).present?
          create_multiple_freechip_rewards_if_provided
        end
        # Create multiple material_prize rewards if provided
        if params[:material_prize_rewards].present? || params.dig(:bonus, :material_prize_rewards).present?
          create_multiple_material_prize_rewards_if_provided
        end
        update_type_specific_attributes
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

    # Set currency from currencies array if needed
    bonus_attributes = bonus_params
    if bonus_attributes[:currencies].present?
      # Filter out blank currencies
      valid_currencies = bonus_attributes[:currencies].reject(&:blank?)
      # No need to set currency field as it was removed
    end

    respond_to do |format|
      if @bonus.update(bonus_attributes)
        # Update or create bonus rewards if provided (singular or multiple)
        update_bonus_reward_if_provided
        update_multiple_bonus_rewards_if_provided
        # Update or create freespin rewards if provided (singular or multiple) - only one should be called
        if params[:freespin_rewards].present? || params.dig(:bonus, :freespin_rewards).present?
          update_multiple_freespin_rewards_if_provided
        elsif params[:freespin_reward].present? || params.dig(:bonus, :freespin_reward).present?
          update_freespin_reward_if_provided
        end
        # Update or create bonus_buy rewards if provided (singular or multiple)
        update_bonus_buy_reward_if_provided
        update_multiple_bonus_buy_rewards_if_provided
        # Update or create comp_point rewards if provided (singular or multiple)
        update_multiple_comp_point_rewards_if_provided
        # Update or create bonus_code rewards if provided (singular or multiple)
        update_multiple_bonus_code_rewards_if_provided
        # Update or create freechip rewards if provided (singular or multiple)
        update_multiple_freechip_rewards_if_provided
        # Update or create material_prize rewards if provided (singular or multiple)
        update_multiple_material_prize_rewards_if_provided
        update_type_specific_attributes
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

  # GET /bonuses/find_template
  def find_template
    dsl_tag = params[:dsl_tag]
    name = params[:name]
    project = params[:project]

    # Only dsl_tag and name are required
    if dsl_tag.blank? || name.blank?
      render json: {
        error: "dsl_tag and name are required",
        missing_params: {
          dsl_tag: dsl_tag.blank?,
          name: name.blank?
        }
      }, status: :bad_request
      return
    end

    # Use the existing method to find template with all three parameters
    template = BonusTemplate.find_template_by_dsl_and_name(dsl_tag, name, project)

    if template
      render json: {
        template: template.as_json(except: [ :created_at, :updated_at ]),
        found_by: template.for_all_projects? ? "All projects" : "Project: #{template.project}"
      }
    else
      render json: {
        error: "Template not found",
        searched_for: "dsl_tag: #{dsl_tag}, name: #{name}, project: #{project}"
      }, status: :not_found
    end
  end

  private

  def bonus_includes
    [ :bonus_rewards, :freespin_rewards, :bonus_buy_rewards,
      :freechip_rewards, :bonus_code_rewards, :material_prize_rewards, :comp_point_rewards ]
  end

  def generate_preview_data
    # This is a placeholder. In a real application, this method would
    # generate preview data based on the bonus's settings.
    {
      title: @bonus.name,
      description: @bonus.description,
      rewards: @bonus.all_rewards.map { |r| { type: r.class.name, details: r.attributes } }
    }
  end

  def set_bonus
    @bonus = Bonus.find(params[:id])
  end

  def bonus_params
    params.require(:bonus).permit(
      :name, :code, :event, :status, :wager,
      :maximum_winnings, :wagering_strategy, :availability_start_date,
      :availability_end_date, :user_group, :tags, :country,
      :project, :dsl_tag, :created_by, :updated_by, :no_more, :totally_no_more,
      :description, :groups, :minimum_deposit,
      currencies: [], currency_minimum_deposits: {}
    )
  end

  def bonus_reward_params
    puts "bonus_reward_params called"
    puts "params[:bonus_reward]: #{params[:bonus_reward].inspect}"
    return {} unless params[:bonus_reward].present?

    permitted = params.require(:bonus_reward).permit(
      :reward_type, :bonus_type, :amount, :percentage, :wager,
      :max_win_value, :max_win_type,
      :available, :code, :min, :groups, :tags, :user_can_have_duplicates, :wagering_strategy,
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

    permitted.delete(:bonus_type)

    permitted
  end

  def create_bonus_reward_if_provided
    puts "create_bonus_reward_if_provided called"
    reward_params = bonus_reward_params
    puts "reward_params: #{reward_params.inspect}"
    puts "reward_params.empty?: #{reward_params.empty?}"
    puts "reward_params[:amount].blank?: #{reward_params[:amount].blank?}"
    puts "reward_params[:percentage].blank?: #{reward_params[:percentage].blank?}"
    return if reward_params.empty? || (reward_params[:amount].blank? && reward_params[:percentage].blank?)

    reward = @bonus.bonus_rewards.build(
      reward_type: reward_params[:reward_type] || "bonus",
      amount: reward_params[:amount],
      percentage: reward_params[:percentage]
    )

    # Set new direct attributes
    reward.wager = reward_params[:wager] if reward_params[:wager].present?
    reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
    reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.user_can_have_duplicates = reward_params[:user_can_have_duplicates] if reward_params[:user_can_have_duplicates].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?

    # Set all additional parameters through the config field
    config = {}
    reward_params.except(:amount, :percentage, :reward_type, :wager, :max_win_value, :max_win_type, :available, :code, :user_can_have_duplicates, :stag).each do |key, value|
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
    reward_type = reward_params[:reward_type] || "bonus"
    reward = @bonus.bonus_rewards.find_by(reward_type: reward_type) ||
             @bonus.bonus_rewards.build(reward_type: reward_type)

    # Update amount/percentage
    reward.amount = reward_params[:amount] if reward_params[:amount].present?
    reward.percentage = reward_params[:percentage] if reward_params[:percentage].present?

    # Update new direct attributes
    reward.wager = reward_params[:wager] if reward_params[:wager].present?
    reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
    reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.user_can_have_duplicates = reward_params[:user_can_have_duplicates] if reward_params[:user_can_have_duplicates].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?

    # Update config
    config = reward.config || {}
    reward_params.except(:amount, :percentage, :reward_type, :wager, :max_win_value, :max_win_type, :available, :code, :user_can_have_duplicates, :stag).each do |key, value|
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
      :spins_count, :games, :bet_level, :max_win_value, :max_win_type, :available, :code,
      :min, :groups, :tags, :stag, :wagering_strategy,
      # Currency freespin bet levels
      :currency_freespin_bet_levels,
      # Advanced parameters
      :auto_activate, :duration, :activation_duration, :email_template, :range,
      :last_login_country, :profile_country, :current_ip_country, :emails,
      :deposit_payment_systems, :cashout_payment_systems, :user_can_have_duplicates,
      :user_can_have_disposable_email, :total_deposits, :deposits_sum, :loss_sum,
      :deposits_count, :spend_sum, :category_loss_sum, :wager_sum, :bets_count,
      :affiliates_user, :balance, :chargeable_comp_points, :persistent_comp_points,
      :date_of_birth, :deposit, :gender, :issued_bonus, :registered, :social_networks,
      :wager_done, :hold_min, :hold_max, :currencies,
      # Array parameters
      currencies: [], games: []
    )

    # Handle array fields properly
    permitted[:games] = permitted[:games].split(",").map(&:strip) if permitted[:games].is_a?(String)
    permitted[:tags] = permitted[:tags].split(",").map(&:strip) if permitted[:tags].is_a?(String)

    permitted
  end



  def multiple_bonus_rewards_params
    # Check both top-level and nested parameters
    rewards_params = params[:bonus_rewards] || params.dig(:bonus, :bonus_rewards)
    return [] unless rewards_params.present?

    result = rewards_params.values.map do |reward_params|
      permitted = reward_params.permit(
        :id, :bonus_type, :amount, :percentage, :wager,
        :available, :code, :min, :groups, :tags, :user_can_have_duplicates, :wagering_strategy,
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

    result
  end

  def multiple_freespin_rewards_params
    # Check both top-level and nested parameters
    rewards_params = params[:freespin_rewards] || params.dig(:bonus, :freespin_rewards)
    return [] unless rewards_params.present?

    rewards_params.values.map do |reward_params|
      next if reward_params.blank? || reward_params[:spins_count].blank?

      permitted = reward_params.permit(
        :id, :spins_count, :games, :bet_level, :max_win_value, :max_win_type, :available, :code,
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
        currency_bet_levels: {},
        currency_freespin_bet_levels: {}
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
      Rails.logger.debug "Processing reward_params: #{reward_params.inspect}"
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
      Rails.logger.debug "Saving reward: #{reward.inspect}"
      Rails.logger.debug "Reward valid? #{reward.valid?}"
      Rails.logger.debug "Reward errors: #{reward.errors.full_messages}" unless reward.valid?
      result = reward.save
      Rails.logger.debug "Reward save result: #{result}"
      Rails.logger.debug "Reward saved: #{reward.persisted?}, errors: #{reward.errors.full_messages}"
    end
  end

  def create_multiple_freespin_rewards_if_provided
    rewards_params = multiple_freespin_rewards_params
    return if rewards_params.empty?

    Rails.logger.debug "Creating multiple freespin rewards with params: #{rewards_params.inspect}"

    rewards_params.each do |reward_params|
      # Prepare currency freespin bet levels first
      currency_bet_levels = if reward_params[:currency_freespin_bet_levels].present?
        reward_params[:currency_freespin_bet_levels]
      elsif @bonus.currencies.present?
        default_levels = {}
        bet_level_value = reward_params[:bet_level] || 0.1  # Use bet_level or default to 0.1
        @bonus.currencies.each { |currency| default_levels[currency] = bet_level_value }
        default_levels
      else
        {}
      end

      reward = @bonus.freespin_rewards.build(
        spins_count: reward_params[:spins_count]
      )

      # Set common parameters
      reward.games = reward_params[:games] if reward_params[:games].present?
      reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
      reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
      reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
      reward.available = reward_params[:available] if reward_params[:available].present?
      reward.code = reward_params[:code] if reward_params[:code].present?
      reward.stag = reward_params[:stag] if reward_params[:stag].present?

      reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
      reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?

      # Use common parameters from bonus
      reward.min_deposit = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      reward.groups = @bonus.groups if @bonus.groups.present?
      reward.wagering_strategy = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      # reward.currencies = @bonus.currencies if @bonus.currencies.present? # Reward models don't have currencies attribute
      reward.no_more = @bonus.no_more if @bonus.no_more.present?
      reward.totally_no_more = @bonus.totally_no_more if @bonus.totally_no_more.present?

      # Set currency freespin bet levels
      reward.currency_freespin_bet_levels = currency_bet_levels if currency_bet_levels.any?

      # Set advanced parameters
      config = reward.config || {}  # Preserve existing config
      reward.advanced_params.each do |param|
        config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present? && ![ :games, :bet_level, :max_win_value, :max_win_type, :available, :code, :stag ].include?(param.to_sym)
      end

      reward.config = config
      reward.save!
    end
  end

  def update_multiple_bonus_rewards_if_provided
    rewards_params = multiple_bonus_rewards_params
    return if rewards_params.empty?

    # Get existing reward IDs from params
    existing_reward_ids = rewards_params.map { |rp| rp[:id] }.compact

    # Remove rewards that are no longer in the params
    @bonus.bonus_rewards.where.not(id: existing_reward_ids).destroy_all if existing_reward_ids.any?

    rewards_params.each_with_index do |reward_params, index|
      if reward_params[:id].present?
        # Update existing reward
        reward = @bonus.bonus_rewards.find_by(id: reward_params[:id])
        next unless reward

        # Update basic attributes
        reward.amount = reward_params[:amount] if reward_params[:amount].present?
        reward.percentage = reward_params[:percentage] if reward_params[:percentage].present?

        # Update config with all other parameters
        config = reward.config || {}
        reward_params.except(:id, :amount, :percentage).each do |key, value|
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

        reward.config = config
        reward.save
      else
        # Create new reward
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
  end

  def update_multiple_freespin_rewards_if_provided
    rewards_params = multiple_freespin_rewards_params
    return if rewards_params.empty?

    # Get existing reward IDs from params
    existing_reward_ids = rewards_params.map { |rp| rp[:id] }.compact

    # Remove rewards that are no longer in the params
    @bonus.freespin_rewards.where.not(id: existing_reward_ids).destroy_all if existing_reward_ids.any?

    rewards_params.each_with_index do |reward_params, index|
      if reward_params[:id].present?
        # Update existing reward
        reward = @bonus.freespin_rewards.find_by(id: reward_params[:id])
        next unless reward

        # Update basic attributes
        reward.spins_count = reward_params[:spins_count] if reward_params[:spins_count].present?

        # Update common parameters using accessors (these store in config)
        reward.games = reward_params[:games] if reward_params[:games].present?
        reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
        reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
        reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
        reward.available = reward_params[:available] if reward_params[:available].present?
        reward.code = reward_params[:code] if reward_params[:code].present?
        reward.stag = reward_params[:stag] if reward_params[:stag].present?

        # Set currency bet levels
        if reward_params[:currency_bet_levels].present?
          reward.currency_bet_levels = reward_params[:currency_bet_levels]
        end

        # Set advanced parameters and common bonus parameters
        config = reward.config || {}
        reward.advanced_params.each do |param|
          if reward_params[param.to_sym].present? && ![ :games, :bet_level, :max_win_value, :max_win_type, :available, :code, :stag ].include?(param.to_sym)
            config[param] = reward_params[param.to_sym]
          end
        end

        # Add common parameters from bonus
        config["currencies"] = @bonus.currencies if @bonus.currencies.present?
        config["groups"] = @bonus.groups if @bonus.groups.present?
        config["min"] = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
        config["wagering_strategy"] = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
        config["no_more"] = @bonus.no_more if @bonus.no_more.present?
        config["totally_no_more"] = @bonus.totally_no_more if @bonus.totally_no_more.present?

        reward.config = config
        reward.save
      else
        # Create new reward
        next if reward_params[:spins_count].blank?

        reward = @bonus.freespin_rewards.build(
          spins_count: reward_params[:spins_count]
        )

        # Set common parameters
        reward.games = reward_params[:games] if reward_params[:games].present?
        reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
        reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
        reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
        reward.available = reward_params[:available] if reward_params[:available].present?
        reward.code = reward_params[:code] if reward_params[:code].present?
        reward.stag = reward_params[:stag] if reward_params[:stag].present?

        reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
        reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?

        # Set currency bet levels
        if reward_params[:currency_bet_levels].present?
          reward.currency_bet_levels = reward_params[:currency_bet_levels]
        end

        # Set advanced parameters
        config = {}
        reward.advanced_params.each do |param|
          config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present? && ![ :games, :bet_level, :max_win_value, :max_win_type, :available, :code, :stag ].include?(param.to_sym)
        end

        reward.config = config
        reward.save
      end
    end
  end

  def bonus_buy_reward_params
    return {} unless params[:bonus_buy_reward].present?

    permitted = params.require(:bonus_buy_reward).permit(
      :buy_amount, :multiplier, :games, :bet_level, :max_win_value, :max_win_type, :available, :code,
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
    # Check both top-level and nested parameters
    rewards_params = params[:bonus_buy_rewards] || params.dig(:bonus, :bonus_buy_rewards)
    return [] unless rewards_params.present?

    rewards_params.values.map do |reward_params|
      next if reward_params.blank? || reward_params[:buy_amount].blank?

      permitted = reward_params.permit(
        :id, :buy_amount, :multiplier, :games, :bet_level, :max_win_value, :max_win_type, :available, :code,
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
      reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
      reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
      reward.available = reward_params[:available] if reward_params[:available].present?
      reward.code = reward_params[:code] if reward_params[:code].present?
      reward.stag = reward_params[:stag] if reward_params[:stag].present?

      reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
      reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?

      # Use common parameters from bonus
      reward.min_deposit = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
      reward.groups = @bonus.groups if @bonus.groups.present?
      reward.wagering_strategy = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
      # reward.currencies = @bonus.currencies if @bonus.currencies.present? # Reward models don't have currencies attribute
      reward.no_more = @bonus.no_more if @bonus.no_more.present?
      reward.totally_no_more = @bonus.totally_no_more if @bonus.totally_no_more.present?

      # Set advanced parameters
      config = {}
      reward.advanced_params.each do |param|
        config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present?
      end

      # Set currency bet levels
      if reward_params[:currency_bet_levels].present?
        config["currency_bet_levels"] = reward_params[:currency_bet_levels]
      end

      reward.config = config
      reward.save!
    end
  end

  def update_multiple_bonus_buy_rewards_if_provided
    rewards_params = multiple_bonus_buy_rewards_params
    return if rewards_params.empty?

    # Get existing reward IDs from params
    existing_reward_ids = rewards_params.map { |rp| rp[:id] }.compact

    # Remove rewards that are no longer in the params
    @bonus.bonus_buy_rewards.where.not(id: existing_reward_ids).destroy_all if existing_reward_ids.any?

    rewards_params.each_with_index do |reward_params, index|
      if reward_params[:id].present?
        # Update existing reward
        reward = @bonus.bonus_buy_rewards.find_by(id: reward_params[:id])
        next unless reward

        # Update buy amount and multiplier if provided
        reward.buy_amount = reward_params[:buy_amount] if reward_params[:buy_amount].present?
        reward.multiplier = reward_params[:multiplier] if reward_params[:multiplier].present?

        # Update common parameters using accessors (these store in config)
        reward.games = reward_params[:games] if reward_params[:games].present?
        reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
        reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
        reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
        reward.available = reward_params[:available] if reward_params[:available].present?
        reward.code = reward_params[:code] if reward_params[:code].present?
        reward.stag = reward_params[:stag] if reward_params[:stag].present?

        # Set advanced parameters and common bonus parameters
        config = reward.config || {}
        reward.advanced_params.each do |param|
          if reward_params[param.to_sym].present?
            config[param] = reward_params[param.to_sym]
          end
        end

        # Set currency bet levels
        if reward_params[:currency_bet_levels].present?
          config["currency_bet_levels"] = reward_params[:currency_bet_levels]
        end

        # Add common parameters from bonus
        config["currencies"] = @bonus.currencies if @bonus.currencies.present?
        config["groups"] = @bonus.groups if @bonus.groups.present?
        config["min"] = @bonus.minimum_deposit if @bonus.minimum_deposit.present?
        config["wagering_strategy"] = @bonus.wagering_strategy if @bonus.wagering_strategy.present?
        config["no_more"] = @bonus.no_more if @bonus.no_more.present?
        config["totally_no_more"] = @bonus.totally_no_more if @bonus.totally_no_more.present?

        reward.config = config
        reward.save
      else
        # Create new reward
        next if reward_params[:buy_amount].blank?

        reward = @bonus.bonus_buy_rewards.build(
          buy_amount: reward_params[:buy_amount],
          multiplier: reward_params[:multiplier]
        )

        # Set common parameters
        reward.games = reward_params[:games] if reward_params[:games].present?
        reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
        reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
        reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
        reward.available = reward_params[:available] if reward_params[:available].present?
        reward.code = reward_params[:code] if reward_params[:code].present?
        reward.stag = reward_params[:stag] if reward_params[:stag].present?

        reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
        reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?

        # Set advanced parameters
        config = {}
        reward.advanced_params.each do |param|
          config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present? && ![ :games, :bet_level, :max_win_value, :max_win_type, :available, :code, :stag ].include?(param.to_sym)
        end

        # Set currency bet levels
        if reward_params[:currency_bet_levels].present?
          config["currency_bet_levels"] = reward_params[:currency_bet_levels]
        end

        reward.config = config
        reward.save
      end
    end
  end

  def create_comp_point_reward_if_provided
    reward_params = comp_point_reward_params
    return if reward_params.empty? || (reward_params[:points].blank? && reward_params[:points_amount].blank?)

    reward = @bonus.comp_point_rewards.build

    # Set main attributes
    reward.points_amount = reward_params[:points_amount] || reward_params[:points]
    reward.title = reward_params[:title] if reward_params[:title].present?

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

  def update_comp_point_reward_if_provided
    reward_params = comp_point_reward_params
    return if reward_params.empty?

    # Find existing comp_point reward or create new one
    reward = @bonus.comp_point_rewards.first || @bonus.comp_point_rewards.build

    # Update main attributes
    reward.comp_points_amount = reward_params[:comp_points_amount] if reward_params[:comp_points_amount].present?
    reward.comp_points_percentage = reward_params[:comp_points_percentage] if reward_params[:comp_points_percentage].present?

    # Update config
    config = reward.config || {}
    reward_params.except(:comp_points_amount, :comp_points_percentage).each do |key, value|
      if value.blank?
        config.delete(key.to_s)
      else
        config[key.to_s] = value
      end
    end

    reward.config = config unless config.empty?
    reward.save
  end

  def create_bonus_code_reward_if_provided
    reward_params = bonus_code_reward_params
    return if reward_params.empty? || reward_params[:set_bonus_code].blank?

    reward = @bonus.bonus_code_rewards.build(
      code: reward_params[:set_bonus_code],
      title: reward_params[:title]
    )

    # Set all additional parameters through the config field
    config = {}
    reward_params.except(:set_bonus_code, :title).each do |key, value|
      next if value.blank?
      config[key.to_s] = value
    end

    reward.config = config unless config.empty?
    reward.save
  end

  def update_bonus_code_reward_if_provided
    reward_params = bonus_code_reward_params
    return if reward_params.empty?

    # Find existing bonus_code reward or create new one
    reward = @bonus.bonus_code_rewards.first || @bonus.bonus_code_rewards.build

    # Update main attributes
    reward.code = reward_params[:set_bonus_code] if reward_params[:set_bonus_code].present?
    reward.title = reward_params[:title] if reward_params[:title].present?

    # Update config
    config = reward.config || {}
    reward_params.except(:set_bonus_code, :title).each do |key, value|
      if value.blank?
        config.delete(key.to_s)
      else
        config[key.to_s] = value
      end
    end

    reward.config = config unless config.empty?
    reward.save
  end

  # Duplicate method removed - using the first definition



  def update_type_specific_attributes
    # This method is called after bonus creation/update to handle type-specific attributes
    # Currently handled by reward associations, so this is a no-op
  end

  private

  def set_bonus
    @bonus = Bonus.find(params[:id])
  end

  def bonus_params
    params.require(:bonus).permit(
      :name, :code, :event, :status, :wager,
      :maximum_winnings, :wagering_strategy, :availability_start_date,
      :availability_end_date, :user_group, :tags, :country,
      :project, :dsl_tag, :created_by, :updated_by, :no_more, :totally_no_more,
      :description,
      currencies: [], groups: [], currency_minimum_deposits: {}
    )
  end

  def bonus_reward_params
    return {} unless params[:bonus_reward].present?

    permitted = params.require(:bonus_reward).permit(
      :reward_type, :bonus_type, :amount, :percentage, :wager,
      :max_win_value, :max_win_type,
      :available, :code, :min, :groups, :tags, :user_can_have_duplicates, :wagering_strategy,
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

    permitted.delete(:bonus_type)

    permitted
  end

  def create_bonus_reward_if_provided
    reward_params = bonus_reward_params
    return if reward_params.empty? || (reward_params[:amount].blank? && reward_params[:percentage].blank?)

    reward = @bonus.bonus_rewards.build(
      reward_type: reward_params[:reward_type] || "bonus",
      amount: reward_params[:amount],
      percentage: reward_params[:percentage]
    )

    # Set new direct attributes
    reward.wager = reward_params[:wager] if reward_params[:wager].present?
    reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
    reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.user_can_have_duplicates = reward_params[:user_can_have_duplicates] if reward_params[:user_can_have_duplicates].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?

    # Set all additional parameters through the config field
    config = {}
    reward_params.except(:amount, :percentage, :reward_type, :wager, :max_win_value, :max_win_type, :available, :code, :user_can_have_duplicates, :stag).each do |key, value|
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
    reward_type = reward_params[:reward_type] || "bonus"
    reward = @bonus.bonus_rewards.find_by(reward_type: reward_type) ||
             @bonus.bonus_rewards.build(reward_type: reward_type)

    # Update amount/percentage
    reward.amount = reward_params[:amount] if reward_params[:amount].present?
    reward.percentage = reward_params[:percentage] if reward_params[:percentage].present?

    # Update new direct attributes
    reward.wager = reward_params[:wager] if reward_params[:wager].present?
    reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
    reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.user_can_have_duplicates = reward_params[:user_can_have_duplicates] if reward_params[:user_can_have_duplicates].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?

    # Update config
    config = reward.config || {}
    reward_params.except(:amount, :percentage, :reward_type, :wager, :max_win_value, :max_win_type, :available, :code, :user_can_have_duplicates, :stag).each do |key, value|
      if value.blank?
        config.delete(key.to_s)
      else
        config[key.to_s] = value
      end
    end

    reward.config = config
    reward.save
  end

  def create_freespin_reward_if_provided
    reward_params = freespin_reward_params
    return if reward_params.empty? || reward_params[:spins_count].blank?



    # Prepare currency freespin bet levels first
    currency_bet_levels = if reward_params[:currency_freespin_bet_levels].present?
      reward_params[:currency_freespin_bet_levels]
    elsif @bonus.currencies.present?
      default_levels = {}
      bet_level_value = reward_params[:bet_level] || 0.1  # Use bet_level or default to 0.1
      @bonus.currencies.each { |currency| default_levels[currency] = bet_level_value }
      default_levels
    else
      {}
    end

    reward = @bonus.freespin_rewards.build(
      spins_count: reward_params[:spins_count],
      games: reward_params[:games],
      bet_level: reward_params[:bet_level],
      max_win_value: reward_params[:max_win_value],
      max_win_type: reward_params[:max_win_type],
      available: reward_params[:available],
      code: reward_params[:code],
      stag: reward_params[:stag]
    )

    # Set currency freespin bet levels
    reward.currency_freespin_bet_levels = currency_bet_levels if currency_bet_levels.any?

    # Set advanced parameters
    config = reward.config || {}  # Preserve existing config
    reward.advanced_params.each do |param|
      config[param] = reward_params[param.to_sym] if reward_params[param.to_sym].present? && ![ :games, :bet_level, :max_win_value, :max_win_type, :available, :code, :stag ].include?(param.to_sym)
    end

    reward.config = config
    reward.save!
  end

  def update_freespin_reward_if_provided
    reward_params = freespin_reward_params
    return if reward_params.empty?

    # Find existing freespin reward or create new one
    reward = @bonus.freespin_rewards.first || @bonus.freespin_rewards.build

    # Update main attributes
    reward.spins_count = reward_params[:spins_count] if reward_params[:spins_count].present?
    reward.games = reward_params[:games] if reward_params[:games].present?
    reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
    reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
    reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?

    reward.no_more = reward_params[:no_more] if reward_params[:no_more].present?
    reward.totally_no_more = reward_params[:totally_no_more] if reward_params[:totally_no_more].present?
    reward.min_deposit = reward_params[:min] if reward_params[:min].present?

    # Update advanced parameters
    config = reward.config || {}
    reward.advanced_params.each do |param|
      if reward_params[param.to_sym].present? && ![ :games, :bet_level, :max_win_value, :max_win_type, :available, :code, :stag ].include?(param.to_sym)
        config[param] = reward_params[param.to_sym]
      end
    end

    reward.config = config
    reward.save
  end

  def create_bonus_buy_reward_if_provided
    reward_params = bonus_buy_reward_params
    return if reward_params.empty? || reward_params[:bonus_buy_amount].blank?

    reward = @bonus.bonus_buy_rewards.build(
      bonus_buy_amount: reward_params[:bonus_buy_amount],
      bonus_buy_games: reward_params[:bonus_buy_games],
      bonus_buy_percentage: reward_params[:bonus_buy_percentage]
    )

    # Set new direct attributes
    reward.games = reward_params[:games] if reward_params[:games].present?
    reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
    reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
    reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?


    # Set all additional parameters through the config field
    config = {}
    reward_params.except(:bonus_buy_amount, :bonus_buy_games, :bonus_buy_percentage, :games, :bet_level, :max_win_value, :max_win_type, :available, :code, :stag).each do |key, value|
      next if value.blank?
      config[key.to_s] = value
    end

    reward.config = config unless config.empty?
    reward.save
  end

  def update_bonus_buy_reward_if_provided
    reward_params = bonus_buy_reward_params
    return if reward_params.empty?

    # Find existing bonus_buy reward or create new one
    reward = @bonus.bonus_buy_rewards.first || @bonus.bonus_buy_rewards.build

    # Update main attributes
    reward.bonus_buy_amount = reward_params[:bonus_buy_amount] if reward_params[:bonus_buy_amount].present?
    reward.bonus_buy_games = reward_params[:bonus_buy_games] if reward_params[:bonus_buy_games].present?
    reward.bonus_buy_percentage = reward_params[:bonus_buy_percentage] if reward_params[:bonus_buy_percentage].present?

    # Set new direct attributes
    reward.games = reward_params[:games] if reward_params[:games].present?
    reward.bet_level = reward_params[:bet_level] if reward_params[:bet_level].present?
    reward.max_win_value = reward_params[:max_win_value] if reward_params[:max_win_value].present?
    reward.max_win_type = reward_params[:max_win_type] if reward_params[:max_win_type].present?
    reward.available = reward_params[:available] if reward_params[:available].present?
    reward.code = reward_params[:code] if reward_params[:code].present?
    reward.stag = reward_params[:stag] if reward_params[:stag].present?

    # Update config
    config = reward.config || {}
    reward_params.except(:bonus_buy_amount, :bonus_buy_games, :bonus_buy_percentage, :games, :bet_level, :max_win_value, :max_win_type, :available, :code, :stag).each do |key, value|
      if value.blank?
        config.delete(key.to_s)
      else
        config[key.to_s] = value
      end
    end

    reward.config = config unless config.empty?
    reward.save
  end

  def create_comp_point_reward_if_provided
    reward_params = comp_point_reward_params
    return if reward_params.empty? || (reward_params[:points].blank? && reward_params[:points_amount].blank?)

    reward = @bonus.comp_point_rewards.build

    # Set main attributes
    reward.points_amount = reward_params[:points_amount] || reward_params[:points]
    reward.title = reward_params[:title] if reward_params[:title].present?

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

  def update_comp_point_reward_if_provided
    reward_params = comp_point_reward_params
    return if reward_params.empty?

    # Find existing comp_point reward or create new one
    reward = @bonus.comp_point_rewards.first || @bonus.comp_point_rewards.build

    # Update main attributes
    reward.comp_points_amount = reward_params[:comp_points_amount] if reward_params[:comp_points_amount].present?
    reward.comp_points_percentage = reward_params[:comp_points_percentage] if reward_params[:comp_points_percentage].present?

    # Update config
    config = reward.config || {}
    reward_params.except(:comp_points_amount, :comp_points_percentage).each do |key, value|
      if value.blank?
        config.delete(key.to_s)
      else
        config[key.to_s] = value
      end
    end

    reward.config = config unless config.empty?
    reward.save
  end

  def create_bonus_code_reward_if_provided
    reward_params = bonus_code_reward_params
    return if reward_params.empty? || reward_params[:set_bonus_code].blank?

    reward = @bonus.bonus_code_rewards.build(
      code: reward_params[:set_bonus_code],
      title: reward_params[:title]
    )

    # Set all additional parameters through the config field
    config = {}
    reward_params.except(:set_bonus_code, :title).each do |key, value|
      next if value.blank?
      config[key.to_s] = value
    end

    reward.config = config unless config.empty?
    reward.save
  end

  def update_bonus_code_reward_if_provided
    reward_params = bonus_code_reward_params
    return if reward_params.empty?

    # Find existing bonus_code reward or create new one
    reward = @bonus.bonus_code_rewards.first || @bonus.bonus_code_rewards.build

    # Update main attributes
    reward.code = reward_params[:set_bonus_code] if reward_params[:set_bonus_code].present?
    reward.title = reward_params[:title] if reward_params[:title].present?

    # Update config
    config = reward.config || {}
    reward_params.except(:set_bonus_code, :title).each do |key, value|
      if value.blank?
        config.delete(key.to_s)
      else
        config[key.to_s] = value
      end
    end

    reward.config = config unless config.empty?
    reward.save
  end

  # Duplicate method removed - using the first definition



  def update_type_specific_attributes
    # This method is called after bonus creation/update to handle type-specific attributes
    # Currently handled by reward associations, so this is a no-op
  end

  # Multiple comp_point rewards methods
  def create_multiple_comp_point_rewards_if_provided
    rewards_params = multiple_comp_point_rewards_params
    return if rewards_params.empty?

    rewards_params.each do |reward_params|
      next if reward_params[:points_amount].blank?

      reward = @bonus.comp_point_rewards.build(
        points_amount: reward_params[:points_amount],
        multiplier: reward_params[:multiplier],
        title: reward_params[:title]
      )

      # Set config
      config = {}
      reward_params.except(:points_amount, :multiplier, :title).each do |key, value|
        next if value.blank?
        config[key.to_s] = value
      end

      reward.config = config unless config.empty?
      reward.save!
    end
  end

  def update_multiple_comp_point_rewards_if_provided
    rewards_params = multiple_comp_point_rewards_params
    return if rewards_params.empty?

    # Remove existing comp_point rewards that are not in the new params
    existing_rewards = @bonus.comp_point_rewards.to_a
    rewards_to_keep = []

    rewards_params.each_with_index do |reward_params, index|
      next if reward_params[:points_amount].blank?

      if reward = existing_rewards[index]
        # Update existing reward
        reward.update!(
          points_amount: reward_params[:points_amount],
          multiplier: reward_params[:multiplier],
          title: reward_params[:title]
        )

        # Update config
        config = {}
        reward_params.except(:points_amount, :multiplier, :title).each do |key, value|
          next if value.blank?
          config[key.to_s] = value
        end
        reward.update!(config: config)

        rewards_to_keep << reward
      else
        # Create new reward
        reward = @bonus.comp_point_rewards.build(
          points_amount: reward_params[:points_amount],
          multiplier: reward_params[:multiplier],
          title: reward_params[:title]
        )

        # Set config
        config = {}
        reward_params.except(:points_amount, :multiplier, :title).each do |key, value|
          next if value.blank?
          config[key.to_s] = value
        end

        reward.config = config unless config.empty?
        reward.save!
        rewards_to_keep << reward
      end
    end

    # Remove extra rewards
    existing_rewards.each do |reward|
      reward.destroy unless rewards_to_keep.include?(reward)
    end
  end

  # Multiple bonus_code rewards methods
  def create_multiple_bonus_code_rewards_if_provided
    rewards_params = multiple_bonus_code_rewards_params
    return if rewards_params.empty?

    rewards_params.each do |reward_params|
      next if reward_params[:code].blank?

      reward = @bonus.bonus_code_rewards.build(
        code: reward_params[:code],
        code_type: reward_params[:code_type] || "bonus",
        title: reward_params[:title]
      )

      # Set config
      config = {}
      reward_params.except(:code, :code_type, :title).each do |key, value|
        next if value.blank?
        config[key.to_s] = value
      end

      reward.config = config unless config.empty?
      reward.save!
    end
  end

  def update_multiple_bonus_code_rewards_if_provided
    rewards_params = multiple_bonus_code_rewards_params
    return if rewards_params.empty?

    # Remove existing bonus_code rewards that are not in the new params
    existing_rewards = @bonus.bonus_code_rewards.to_a
    rewards_to_keep = []

    rewards_params.each_with_index do |reward_params, index|
      next if reward_params[:code].blank?

      if reward = existing_rewards[index]
        # Update existing reward
        reward.update!(
          code: reward_params[:code],
          code_type: reward_params[:code_type] || "bonus",
          title: reward_params[:title]
        )

        # Update config
        config = {}
        reward_params.except(:code, :code_type, :title).each do |key, value|
          next if value.blank?
          config[key.to_s] = value
        end
        reward.update!(config: config)

        rewards_to_keep << reward
      else
        # Create new reward
        reward = @bonus.bonus_code_rewards.build(
          code: reward_params[:code],
          code_type: reward_params[:code_type] || "bonus",
          title: reward_params[:title]
        )

        # Set config
        config = {}
        reward_params.except(:code, :code_type, :title).each do |key, value|
          next if value.blank?
          config[key.to_s] = value
        end

        reward.config = config unless config.empty?
        reward.save!
        rewards_to_keep << reward
      end
    end

    # Remove extra rewards
    existing_rewards.each do |reward|
      reward.destroy unless rewards_to_keep.include?(reward)
    end
  end

  # Multiple freechip rewards methods
  def create_multiple_freechip_rewards_if_provided
    rewards_params = multiple_freechip_rewards_params
    return if rewards_params.empty?

    rewards_params.each do |reward_params|
      next if reward_params[:chip_value].blank? || reward_params[:chips_count].blank?

      reward = @bonus.freechip_rewards.build(
        chip_value: reward_params[:chip_value],
        chips_count: reward_params[:chips_count]
      )

      # Set config
      config = {}
      reward_params.except(:chip_value, :chips_count).each do |key, value|
        next if value.blank?
        config[key.to_s] = value
      end

      reward.config = config unless config.empty?
      reward.save!
    end
  end

  def update_multiple_freechip_rewards_if_provided
    rewards_params = multiple_freechip_rewards_params
    return if rewards_params.empty?

    # Remove existing freechip rewards that are not in the new params
    existing_rewards = @bonus.freechip_rewards.to_a
    rewards_to_keep = []

    rewards_params.each_with_index do |reward_params, index|
      next if reward_params[:chip_value].blank? || reward_params[:chips_count].blank?

      if reward = existing_rewards[index]
        # Update existing reward
        reward.update!(
          chip_value: reward_params[:chip_value],
          chips_count: reward_params[:chips_count]
        )

        # Update config
        config = {}
        reward_params.except(:chip_value, :chips_count).each do |key, value|
          next if value.blank?
          config[key.to_s] = value
        end
        reward.update!(config: config)

        rewards_to_keep << reward
      else
        # Create new reward
        reward = @bonus.freechip_rewards.build(
          chip_value: reward_params[:chip_value],
          chips_count: reward_params[:chips_count]
        )

        # Set config
        config = {}
        reward_params.except(:chip_value, :chips_count).each do |key, value|
          next if value.blank?
          config[key.to_s] = value
        end

        reward.config = config unless config.empty?
        reward.save!
        rewards_to_keep << reward
      end
    end

    # Remove extra rewards
    existing_rewards.each do |reward|
      reward.destroy unless rewards_to_keep.include?(reward)
    end
  end

  # Multiple material_prize rewards methods
  def create_multiple_material_prize_rewards_if_provided
    rewards_params = multiple_material_prize_rewards_params
    return if rewards_params.empty?

    rewards_params.each do |reward_params|
      next if reward_params[:prize_name].blank?

      reward = @bonus.material_prize_rewards.build(
        prize_name: reward_params[:prize_name],
        prize_value: reward_params[:prize_value]
      )

      # Set config
      config = {}
      reward_params.except(:prize_name, :prize_value).each do |key, value|
        next if value.blank?
        config[key.to_s] = value
      end

      reward.config = config unless config.empty?
      reward.save!
    end
  end

  def update_multiple_material_prize_rewards_if_provided
    rewards_params = multiple_material_prize_rewards_params
    return if rewards_params.empty?

    # Remove existing material_prize rewards that are not in the new params
    existing_rewards = @bonus.material_prize_rewards.to_a
    rewards_to_keep = []

    rewards_params.each_with_index do |reward_params, index|
      next if reward_params[:prize_name].blank?

      if reward = existing_rewards[index]
        # Update existing reward
        reward.update!(
          prize_name: reward_params[:prize_name],
          prize_value: reward_params[:prize_value]
        )

        # Update config
        config = {}
        reward_params.except(:prize_name, :prize_value).each do |key, value|
          next if value.blank?
          config[key.to_s] = value
        end
        reward.update!(config: config)

        rewards_to_keep << reward
      else
        # Create new reward
        reward = @bonus.material_prize_rewards.build(
          prize_name: reward_params[:prize_name],
          prize_value: reward_params[:prize_value]
        )

        # Set config
        config = {}
        reward_params.except(:prize_name, :prize_value).each do |key, value|
          next if value.blank?
          config[key.to_s] = value
        end

        reward.config = config unless config.empty?
        reward.save!
        rewards_to_keep << reward
      end
    end

    # Remove extra rewards
    existing_rewards.each do |reward|
      reward.destroy unless rewards_to_keep.include?(reward)
    end
  end

  # Parameter methods for multiple rewards
  def multiple_comp_point_rewards_params
    return [] unless params[:comp_point_rewards].present? || params.dig(:bonus, :comp_point_rewards).present?

    rewards_data = params[:comp_point_rewards] || params.dig(:bonus, :comp_point_rewards) || []
    return [] unless rewards_data.respond_to?(:values)

    rewards_data.values.map do |reward_params|
      next if reward_params.blank?
      permitted = reward_params.permit(:points_amount, :points, :multiplier, :title)
      # Map 'points' to 'points_amount' for backward compatibility
      permitted[:points_amount] = permitted[:points] if permitted[:points].present?
      permitted.except(:points)
    end.compact
  end

  def multiple_bonus_code_rewards_params
    return [] unless params[:bonus_code_rewards].present? || params.dig(:bonus, :bonus_code_rewards).present?

    rewards_data = params[:bonus_code_rewards] || params.dig(:bonus, :bonus_code_rewards) || []
    return [] unless rewards_data.respond_to?(:values)

    rewards_data.values.map do |reward_params|
      next if reward_params.blank?
      permitted = reward_params.permit(:code, :set_bonus_code, :code_type, :title)
      # Map 'set_bonus_code' to 'code' for backward compatibility
      permitted[:code] = permitted[:set_bonus_code] if permitted[:set_bonus_code].present?
      permitted.except(:set_bonus_code)
    end.compact
  end

  def multiple_freechip_rewards_params
    return [] unless params[:freechip_rewards].present? || params.dig(:bonus, :freechip_rewards).present?

    rewards_data = params[:freechip_rewards] || params.dig(:bonus, :freechip_rewards) || []
    return [] unless rewards_data.respond_to?(:values)

    rewards_data.values.map do |reward_params|
      next if reward_params.blank?
      reward_params.permit(:chip_value, :chips_count)
    end.compact
  end

  def multiple_material_prize_rewards_params
    return [] unless params[:material_prize_rewards].present? || params.dig(:bonus, :material_prize_rewards).present?

    rewards_data = params[:material_prize_rewards] || params.dig(:bonus, :material_prize_rewards) || []
    return [] unless rewards_data.respond_to?(:values)

    rewards_data.values.map do |reward_params|
      next if reward_params.blank?
      reward_params.permit(:prize_name, :prize_value)
    end.compact
  end

  # Single reward parameter methods
  def comp_point_reward_params
    return {} unless params[:comp_point_reward].present? || params.dig(:bonus, :comp_point_reward).present?

    reward_data = params[:comp_point_reward] || params.dig(:bonus, :comp_point_reward) || {}
    permitted = reward_data.permit(:points_amount, :points, :multiplier, :title, :config_json)
    # Map 'points' to 'points_amount' for backward compatibility
    permitted[:points_amount] = permitted[:points] if permitted[:points].present?
    permitted.except(:points)
  end

  def bonus_code_reward_params
    return {} unless params[:bonus_code_reward].present? || params.dig(:bonus, :bonus_code_reward).present?

    reward_data = params[:bonus_code_reward] || params.dig(:bonus, :bonus_code_reward) || {}
    reward_data.permit(:code, :set_bonus_code, :code_type, :title)
  end

  private
end
