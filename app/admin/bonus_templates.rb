ActiveAdmin.register BonusTemplate do
  # Application Settings - Bonus Templates Management
  menu label: "Bonus Templates", parent: "Application Settings", priority: 2
  
  permit_params :name, :dsl_tag, :project, :event, :currency, :minimum_deposit,
                :wager, :maximum_winnings, :no_more, :totally_no_more,
                :description, currencies: [], groups: [], currency_minimum_deposits: {}

  # Фильтры
  filter :name
  filter :dsl_tag
  filter :project, as: :select, collection: -> { Project.order(:name).pluck(:name) }
  filter :event, as: :select, collection: BonusTemplate::EVENT_TYPES
  filter :created_at
  filter :updated_at

  # Настройка индексной страницы
  index do
    selectable_column
    id_column
    
    column :name
    column :dsl_tag do |template|
      status_tag template.dsl_tag, class: :info
    end
    column :project do |template|
      status_tag template.project, class: :ok
    end
    column :event do |template|
      status_tag template.event.humanize, class: :warning
    end
    column :description do |template|
      truncate(template.description, length: 50) if template.description.present?
    end
    column :minimum_deposit
    column :wager
    column :maximum_winnings
    column :currencies do |template|
      template.formatted_currencies if template.currencies.present?
    end
    column :created_at
    column :updated_at

    actions
  end

  # Детальная страница шаблона
  show do
    attributes_table do
      row :id
      row :name
      row :dsl_tag do |template|
        status_tag template.dsl_tag, class: :info
      end
      row :project do |template|
        status_tag template.project, class: :ok
      end
      row :event do |template|
        status_tag template.event.humanize, class: :warning
      end
      row :description
      row :minimum_deposit
      row :wager
      row :maximum_winnings
      row :maximum_winnings_type
      row :no_more
      row :totally_no_more
      row :currencies do |template|
        template.formatted_currencies
      end
      row :groups do |template|
        template.formatted_groups
      end
      row :currency_minimum_deposits do |template|
        template.formatted_currency_minimum_deposits
      end
      row :created_at
      row :updated_at
    end

    # Панель с бонусами, использующими этот шаблон
    panel "Бонусы, использующие этот шаблон" do
      bonuses = Bonus.where(dsl_tag: bonus_template.dsl_tag, project: bonus_template.project)
      if bonuses.any?
        table_for bonuses do
          column :id do |bonus|
            link_to bonus.id, admin_bonus_path(bonus)
          end
          column :name do |bonus|
            link_to bonus.name, admin_bonus_path(bonus)
          end
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
          column :created_at
        end
      else
        div class: "blank_slate_container" do
          span class: "blank_slate" do
            span "Нет бонусов, использующих этот шаблон"
          end
        end
      end
    end
  end

  # Форма создания/редактирования
  form do |f|
    f.inputs "Основная информация" do
      f.input :name, hint: "Уникальное имя шаблона"
      f.input :dsl_tag, hint: "DSL тег для идентификации шаблона"
      f.input :project, as: :select, collection: Project.order(:name).pluck(:name), 
              hint: "Проект, для которого предназначен шаблон"
      f.input :event, as: :select, collection: BonusTemplate::EVENT_TYPES.map { |e| [e.humanize, e] },
              hint: "Тип события бонуса"
      f.input :description, as: :text, hint: "Описание шаблона (максимум 1000 символов)"
    end

    f.inputs "Финансовые параметры" do
      f.input :minimum_deposit, hint: "Минимальный депозит"
      f.input :wager, hint: "Вейджер (множитель отыгрыша)"
      f.input :maximum_winnings, hint: "Максимальный выигрыш"
      f.input :maximum_winnings_type, as: :select, collection: %w[fixed multiplier],
              hint: "Тип максимального выигрыша"
      f.input :no_more, hint: "Больше нельзя использовать"
      f.input :totally_no_more, hint: "Полностью больше нельзя использовать"
    end

    f.inputs "Валюты и группы" do
      f.input :currencies, as: :check_boxes, collection: BonusTemplate.all_currencies,
              hint: "Валюты, для которых действует шаблон"
      f.input :groups, as: :check_boxes, collection: BonusTemplate.all_groups,
              hint: "Группы пользователей, для которых действует шаблон"
      f.input :currency_minimum_deposits, as: :text, 
              hint: "Минимальные депозиты по валютам (JSON формат: {\"USD\": 10, \"EUR\": 8})"
    end

    f.actions
  end

  # Batch actions
  batch_action :duplicate, confirm: "Дублировать выбранные шаблоны?" do |ids|
    BonusTemplate.where(id: ids).find_each do |template|
      new_template = template.dup
      new_template.name = "#{template.name} (Copy)"
      new_template.save!
    end
    redirect_to collection_path, notice: "Дублировано #{ids.count} шаблонов"
  end

  batch_action :export, confirm: "Экспортировать выбранные шаблоны?" do |ids|
    templates = BonusTemplate.where(id: ids)
    csv_data = CSV.generate do |csv|
      csv << ["Name", "DSL Tag", "Project", "Event", "Description", "Minimum Deposit", "Wager", "Maximum Winnings"]
      templates.each do |template|
        csv << [template.name, template.dsl_tag, template.project, template.event, 
                template.description, template.minimum_deposit, template.wager, template.maximum_winnings]
      end
    end
    
    send_data csv_data, filename: "bonus_templates_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
  end

  # Контроллер
  controller do
    def create
      @bonus_template = BonusTemplate.new(permitted_params[:bonus_template])

      if @bonus_template.save
        redirect_to admin_bonus_template_path(@bonus_template), notice: "Шаблон бонуса успешно создан"
      else
        render :new
      end
    end

    def update
      @bonus_template = BonusTemplate.find(params[:id])

      if @bonus_template.update(permitted_params[:bonus_template])
        redirect_to admin_bonus_template_path(@bonus_template), notice: "Шаблон бонуса успешно обновлен"
      else
        render :edit
      end
    end

    def destroy
      @bonus_template = BonusTemplate.find(params[:id])
      @bonus_template.destroy
      redirect_to admin_bonus_templates_path, notice: "Шаблон бонуса успешно удален"
    end

    private

    def current_user
      current_admin_user
    end
  end
end
