ActiveAdmin.register DslTag do
  menu parent: "Application Settings", priority: 92
  permit_params :name, :description

  # Фильтры
  filter :name
  filter :description
  filter :created_at
  filter :updated_at

  # Настройка индексной страницы
  index do
    selectable_column
    id_column

    column :name
    column :description do |dsl_tag|
      truncate(dsl_tag.description, length: 50) if dsl_tag.description.present?
    end
    column :usage_count do |dsl_tag|
      dsl_tag.usage_count
    end
    column :active_bonuses_count do |dsl_tag|
      dsl_tag.active_bonuses_count
    end
    column :created_at
    column :updated_at

    actions
  end

  # Детальная страница DSL тега
  show do
    attributes_table do
      row :id
      row :name
      row :description
      row :usage_count do |dsl_tag|
        dsl_tag.usage_count
      end
      row :active_bonuses_count do |dsl_tag|
        dsl_tag.active_bonuses_count
      end
      row :created_at
      row :updated_at
    end

    # Панель с бонусами, использующими этот DSL тег
    if dsl_tag.bonuses.any?
      panel "Бонусы с этим DSL тегом" do
        table_for dsl_tag.bonuses.limit(20) do
          column :id
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
          column :created_at
        end

        if dsl_tag.bonuses.count > 20
          div class: "view-all-link" do
            link_to "Показать все бонусы (#{dsl_tag.bonuses.count})",
                    admin_bonuses_path(q: { dsl_tag_id_eq: dsl_tag.id }),
                    class: "button"
          end
        end
      end
    end
  end

  # Форма создания/редактирования
  form do |f|
    f.inputs "DSL Tag" do
      f.input :name, hint: "Уникальное имя DSL тега"
      f.input :description, as: :text, hint: "Описание назначения DSL тега"
    end

    f.actions
  end

  # Batch actions
  batch_action :destroy, confirm: "Удалить выбранные DSL теги?" do |ids|
    DslTag.where(id: ids).find_each do |dsl_tag|
      if dsl_tag.bonuses.any?
        redirect_to collection_path, alert: "DSL тег '#{dsl_tag.name}' используется в бонусах и не может быть удален"
        return
      end
      dsl_tag.destroy
    end
    redirect_to collection_path, notice: "Удалено #{ids.count} DSL тегов"
  end

  # Контроллер
  controller do
    def destroy
      @dsl_tag = DslTag.find(params[:id])

      if @dsl_tag.bonuses.any?
        redirect_to admin_dsl_tags_path, alert: "DSL тег используется в бонусах и не может быть удален"
        return
      end

      @dsl_tag.destroy
      redirect_to admin_dsl_tags_path, notice: "DSL тег успешно удален"
    end

    private

    def current_user
      current_admin_user
    end
  end
end
