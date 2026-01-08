ActiveAdmin.register Bonus do
  permit_params :name, :code, :status, :minimum_deposit, :wager, :maximum_winnings,
                :wagering_strategy, :availability_start_date, :availability_end_date,
                :user_group, :tags, :country, :project, :dsl_tag_id, :event,
                :currencies, :groups, :no_more, :totally_no_more,
                :currency_minimum_deposits, :description, :maximum_winnings_type



  # Фильтры
  filter :name
  filter :code
  filter :status, as: :select, collection: Bonus::STATUSES
  filter :event, as: :select, collection: Bonus::EVENT_TYPES
  filter :project, as: :select, collection: -> { Project.order(:name).pluck(:name) }
  filter :created_by
  filter :updated_by
  filter :created_at
  filter :updated_at
  filter :availability_start_date
  filter :availability_end_date
  # filter :dsl_tag, as: :select, collection: -> { DslTag.order(:name).pluck(:name, :id) }

  # Настройка индексной страницы
  index do
    selectable_column
    id_column

    column :name
    column :code
    column :status do |bonus|
      status_class = case bonus.status
      when "active"
                      :ok
      when "inactive"
                      :error
      when "draft"
                      :warning
      when "expired"
                      :default
      else
                      :default
      end
      status_tag bonus.status, class: status_class
    end
    column :event
    column :project
    column :creator_name
    column :updater_name
    column :created_at
    column :updated_at

    actions do |bonus|
      item "История", admin_bonus_audit_logs_path(bonus_id: bonus.id), class: "member_link"
    end
  end

  # Детальная страница бонуса
  show do
    attributes_table do
      row :id
      row :name
      row :code
      row :status do |bonus|
        status_class = case bonus.status
        when "active"
                        :ok
        when "inactive"
                        :error
        when "draft"
                        :warning
        when "expired"
                        :default
        else
                        :default
        end
        status_tag bonus.status, class: status_class
      end
      row :event
      row :project
      row :dsl_tag do |bonus|
        if bonus.dsl_tag
          link_to bonus.dsl_tag.name, admin_dsl_tag_path(bonus.dsl_tag)
        else
          bonus.dsl_tag || "Не указан"
        end
      end
      row :description
      row :minimum_deposit
      row :wager
      row :maximum_winnings
      row :maximum_winnings_type
      row :wagering_strategy
      row :availability_start_date
      row :availability_end_date
      row :user_group
      row :tags
      row :country
      row :currencies do |bonus|
        bonus.formatted_currencies
      end
      row :groups do |bonus|
        bonus.formatted_groups
      end
      row :currency_minimum_deposits do |bonus|
        bonus.formatted_currency_minimum_deposits
      end
      row :no_more
      row :totally_no_more
      row :created_by do |bonus|
        if bonus.creator
          bonus.creator.full_name || bonus.creator.email
        else
          "System"
        end
      end
      row :updated_by do |bonus|
        if bonus.updater
          bonus.updater.full_name || bonus.updater.email
        else
          "System"
        end
      end
      row :created_at
      row :updated_at
    end

    # Панель с наградами
    if bonus.has_rewards?
      panel "Награды" do
        table_for bonus.all_rewards do
          column :type do |reward|
            reward.class.name.underscore.humanize
          end
          column :details do |reward|
            case reward
            when BonusReward
              "Бонус: #{reward.bonus_amount} #{reward.currency}"
            when FreespinReward
              "Фриспины: #{reward.spins_count} (ставка: #{reward.bet_level})"
            when BonusBuyReward
              "Бонус-бай: #{reward.buy_amount} #{reward.currency}"
            when FreechipReward
              "Фричипы: #{reward.chips_count} x #{reward.chip_value}"
            when BonusCodeReward
              "Код: #{reward.code}"
            when MaterialPrizeReward
              "Приз: #{reward.prize_description}"
            when CompPointReward
              "Очки: #{reward.points_amount}"
            end
          end
          column :created_at
        end
      end
    end

    # Панель с историей изменений
    panel "История изменений" do
      table_for bonus.bonus_audit_logs.recent.limit(10) do
        column :action do |log|
          action_class = case log.action
          when "created"
                          :ok
          when "updated"
                          :warning
          when "deleted"
                          :error
          when "activated"
                          :ok
          when "deactivated"
                          :error
          else
                          :default
          end
          status_tag log.action_label, class: action_class
        end
        column :user do |log|
          log.user.full_name
        end
        column :changes do |log|
          if log.has_changes?
            div class: "changes-preview" do
              log.formatted_changes.split("\n").first(3).each do |change|
                div change
              end
              if log.formatted_changes.split("\n").length > 3
                div "..." + link_to("Показать все", "#", class: "show-all-changes", data: { log_id: log.id })
              end
            end
          else
            "Нет изменений"
          end
        end
        column :created_at
      end

      div class: "view-all-link" do
        link_to "Показать полную историю", admin_bonus_audit_logs_path(bonus_id: bonus.id), class: "button"
        link_to "К списку бонусов", admin_bonuses_path, class: "button"
      end
    end
  end

  # Форма создания/редактирования
  form data: { controller: "bonus-form" } do |f|
    f.inputs "Основная информация" do
      f.input :name, input_html: { data: { "bonus-form-target": "name", action: "change->bonus-form#nameChanged" } }
      f.input :code
      f.input :status, as: :select, collection: Bonus::STATUSES
      f.input :event, as: :select, collection: Bonus::EVENT_TYPES
      f.input :project, as: :select, collection: Project.order(:name).pluck(:name, :id), input_html: { id: "bonus_project_id", data: { "bonus-form-target": "project", action: "change->bonus-form#projectChanged" } }
      f.input :dsl_tag_id, as: :select, collection: DslTag.order(:name).pluck(:name, :id), input_html: { id: "bonus_dsl_tag_id", style: "max-height: 200px; overflow-y: auto;", data: { "bonus-form-target": "dslTag", action: "change->bonus-form#dslTagChanged" } }
      f.input :description
    end

    f.inputs "Финансовые параметры" do
      f.input :minimum_deposit
      f.input :wager
      f.input :maximum_winnings
      f.input :maximum_winnings_type, as: :select, collection: %w[fixed multiplier]
      f.input :wagering_strategy
    end

    f.inputs "Даты и ограничения" do
      f.input :availability_start_date, as: :datetime_picker
      f.input :availability_end_date, as: :datetime_picker
      f.input :no_more
      f.input :totally_no_more
    end

    f.inputs "Группы и теги" do
      f.input :user_group
      f.input :tags
      f.input :country, as: :string
    end

    f.inputs "Валюты и депозиты" do
      f.input :currencies, as: :check_boxes, collection: Bonus.all_currencies
      f.input :groups, as: :check_boxes, collection: Bonus.all_groups
      f.input :currency_minimum_deposits, as: :text, hint: "Формат: {'USD': 10, 'EUR': 8}"
    end

    f.actions
  end

  # Batch actions
  batch_action :activate, confirm: "Активировать выбранные бонусы?" do |ids|
    Bonus.where(id: ids).find_each do |bonus|
      old_status = bonus.status
      bonus.update!(status: "active")
      bonus.log_status_change(current_user, old_status, "active")
    end
    redirect_to collection_path, notice: "Активировано #{ids.count} бонусов"
  end

  batch_action :deactivate, confirm: "Деактивировать выбранные бонусы?" do |ids|
    Bonus.where(id: ids).find_each do |bonus|
      old_status = bonus.status
      bonus.update!(status: "inactive")
      bonus.log_status_change(current_user, old_status, "inactive")
    end
    redirect_to collection_path, notice: "Деактивировано #{ids.count} бонусов"
  end

  # Контроллер
  controller do
    def create
      @bonus = Bonus.new(permitted_params[:bonus])

      if @bonus.save
        redirect_to admin_bonus_path(@bonus), notice: "Бонус успешно создан"
      else
        render :new
      end
    end

    def update
      @bonus = Bonus.find(params[:id])
      old_status = @bonus.status

      if @bonus.update(permitted_params[:bonus])
        @bonus.log_status_change(current_user, old_status, @bonus.status) if old_status != @bonus.status
        redirect_to admin_bonus_path(@bonus), notice: "Бонус успешно обновлен"
      else
        render :edit
      end
    end

    def destroy
      @bonus = Bonus.find(params[:id])
      @bonus.destroy
      redirect_to admin_bonuses_path, notice: "Бонус успешно удален"
    end

    private

    def current_user
      current_admin_user
    end
  end



  # Контроллер
  controller do
    def create
      @bonus = Bonus.new(permitted_params[:bonus])

      if @bonus.save
        redirect_to admin_bonus_path(@bonus), notice: "Бонус успешно создан"
      else
        render :new
      end
    end

    def update
      @bonus = Bonus.find(params[:id])
      old_status = @bonus.status

      if @bonus.update(permitted_params[:bonus])
        @bonus.log_status_change(current_user, old_status, @bonus.status) if old_status != @bonus.status
        redirect_to admin_bonus_path(@bonus), notice: "Бонус успешно обновлен"
      else
        render :edit
      end
    end

    def destroy
      @bonus = Bonus.find(params[:id])
      @bonus.destroy
      redirect_to admin_bonuses_path, notice: "Бонус успешно удален"
    end

    private

    def current_user
      current_admin_user
    end
  end
end
