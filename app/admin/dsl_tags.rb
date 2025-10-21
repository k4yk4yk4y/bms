ActiveAdmin.register_page "DSL Tags" do
  # Application Settings - DSL Tags Management
  menu label: "DSL Tags", parent: "Application Settings", priority: 3

  content title: "DSL Tags Management" do
    # Получаем все уникальные DSL теги с статистикой
    dsl_tags_data = BonusTemplate.group(:dsl_tag)
                                 .select("dsl_tag, COUNT(*) as usage_count, 
                                         COUNT(DISTINCT project) as projects_count,
                                         MIN(created_at) as first_used,
                                         MAX(updated_at) as last_updated")
                                 .order(:dsl_tag)

    # Основная информация
    div class: "panel" do
      h3 "DSL Tags Overview"
      para "Управление DSL тегами для шаблонов бонусов. DSL теги используются для идентификации и группировки шаблонов бонусов."
    end

    # Статистика
    div class: "panel" do
      h3 "Статистика"
      div class: "stats_grid" do
        div class: "stat_item" do
          h4 dsl_tags_data.count
          p "Всего DSL тегов"
        end
        div class: "stat_item" do
          h4 BonusTemplate.count
          p "Всего шаблонов"
        end
        div class: "stat_item" do
          h4 Project.count
          p "Всего проектов"
        end
      end
    end

    # Таблица DSL тегов
    div class: "panel" do
      h3 "Все DSL теги"
      
      if dsl_tags_data.any?
        table class: "index_table" do
          thead do
            tr do
              th "DSL Tag"
              th "Использований"
              th "Проектов"
              th "Первый раз использован"
              th "Последнее обновление"
              th "Действия"
            end
          end
          tbody do
            dsl_tags_data.each do |tag_data|
              tr do
                td do
                  status_tag tag_data.dsl_tag, class: :info
                end
                td do
                  strong tag_data.usage_count
                end
                td do
                  strong tag_data.projects_count
                end
                td do
                  tag_data.first_used&.strftime("%d.%m.%Y %H:%M")
                end
                td do
                  tag_data.last_updated&.strftime("%d.%m.%Y %H:%M")
                end
                td do
                  div class: "action_items" do
                    link_to "Просмотр шаблонов", admin_bonus_templates_path(q: { dsl_tag_eq: tag_data.dsl_tag }),
                            class: "member_link"
                    link_to "Переименовать", admin_dsl_tags_rename_tag_path(tag_name: tag_data.dsl_tag),
                            class: "member_link", method: :get
                    if tag_data.usage_count == 0
                      link_to "Удалить", admin_dsl_tags_delete_tag_path(tag_name: tag_data.dsl_tag),
                              class: "member_link delete_link", method: :delete,
                              confirm: "Вы уверены, что хотите удалить DSL тег '#{tag_data.dsl_tag}'?"
                    end
                  end
                end
              end
            end
          end
        end
      else
        div class: "blank_slate_container" do
          span class: "blank_slate" do
            span "Нет DSL тегов"
          end
        end
      end
    end

  end


  page_action :rename_tag, method: :get do
    @tag_name = params[:tag_name]
    render layout: false
  end

  page_action :update_tag, method: :post do
    old_tag = params[:old_tag]
    new_tag = params[:new_tag]
    
    begin
      # Проверяем, что новый тег не существует
      if BonusTemplate.where(dsl_tag: new_tag).exists?
        redirect_to admin_dsl_tags_path, alert: "DSL тег '#{new_tag}' уже существует"
        return
      end
      
      # Переименовываем все шаблоны с этим тегом
      updated_count = BonusTemplate.where(dsl_tag: old_tag).update_all(dsl_tag: new_tag)
      
      redirect_to admin_dsl_tags_path, notice: "DSL тег успешно переименован. Обновлено #{updated_count} шаблонов."
    rescue => e
      redirect_to admin_dsl_tags_path, alert: "Ошибка при переименовании: #{e.message}"
    end
  end

  page_action :delete_tag, method: :delete do
    tag_name = params[:tag_name]
    
    begin
      # Проверяем, что тег не используется
      if BonusTemplate.where(dsl_tag: tag_name).exists?
        redirect_to admin_dsl_tags_path, alert: "DSL тег используется в шаблонах и не может быть удален"
        return
      end
      
      redirect_to admin_dsl_tags_path, notice: "DSL тег '#{tag_name}' удален (не использовался)"
    rescue => e
      redirect_to admin_dsl_tags_path, alert: "Ошибка при удалении: #{e.message}"
    end
  end
end

