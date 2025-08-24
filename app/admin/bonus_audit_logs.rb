ActiveAdmin.register BonusAuditLog do
  menu false # Скрываем из основного меню



  # Фильтры
  filter :bonus
  filter :user
  filter :action, as: :select, collection: BonusAuditLog::ACTIONS
  filter :created_at

  # Настройка индексной страницы
  index do
    selectable_column
    id_column

    column :bonus do |log|
      link_to log.bonus.name, admin_bonus_path(log.bonus)
    end
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

    actions defaults: false do |log|
      item "Просмотр", admin_bonus_audit_log_path(log)
      item "К бонусу", admin_bonus_path(log.bonus)
    end
  end

  # Детальная страница
  show do
    attributes_table do
      row :id
      row :bonus do |log|
        link_to log.bonus.name, admin_bonus_path(log.bonus)
      end
      row :action do |log|
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
      row :user do |log|
        log.user.full_name
      end
      row :created_at
      row :updated_at
    end

    if bonus_audit_log.has_changes?
      panel "Детали изменений" do
        div class: "changes-details" do
          bonus_audit_log.formatted_changes.split("\n").each do |change|
            div change, class: "change-item"
          end
        end
      end
    end

    if bonus_audit_log.metadata.present?
      panel "Метаданные" do
        attributes_table_for bonus_audit_log do
          bonus_audit_log.metadata.each do |key, value|
            row key.humanize do
              value
            end
          end
        end
      end
    end
  end

  # Контроллер
  controller do
    def scoped_collection
      if params[:bonus_id]
        Bonus.find(params[:bonus_id]).bonus_audit_logs
      else
        super
      end
    end

    def index
      if params[:bonus_id]
        @page_title = "История изменений бонуса ##{params[:bonus_id]}"
      end
      super
    end
  end
end
