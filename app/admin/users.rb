ActiveAdmin.register User do
  permit_params :email, :password, :password_confirmation, :role, :first_name, :last_name

  # Фильтры для поиска пользователей
  filter :email
  filter :role, as: :select, collection: User.roles.keys.map { |role| [ role.humanize, role ] }
  filter :created_at

  # Настройка индексной страницы
  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :role do |user|
      status_tag user.display_role, class: role_status_class(user.role)
    end
    column :created_at
    column :sign_in_count
    column :current_sign_in_at
    column :last_sign_in_at
    actions
  end

  # Детальная страница пользователя
  show do
    attributes_table do
      row :id
      row :email
      row :first_name
      row :last_name
      row :role do |user|
        status_tag user.display_role, class: role_status_class(user.role)
      end
      row :created_at
      row :updated_at
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
      row :current_sign_in_ip
      row :last_sign_in_ip
    end

    panel "Права доступа" do
      attributes_table_for user do
        row "Управление бонусами" do
          user.can_manage_bonuses? ? status_tag("Да", :ok) : status_tag("Нет", :error)
        end
        row "Просмотр маркетинга" do
          user.can_view_marketing? ? status_tag("Да", :ok) : status_tag("Нет", :error)
        end
        row "Доступ к поддержке" do
          user.can_access_support? ? status_tag("Да", :ok) : status_tag("Нет", :error)
        end
        row "Админ доступ" do
          user.can_access_admin? ? status_tag("Да", :ok) : status_tag("Нет", :error)
        end
      end
    end
  end

  # Форма создания/редактирования пользователя
  form do |f|
    f.inputs "Информация о пользователе" do
      f.input :email
      f.input :first_name, label: "Имя"
      f.input :last_name, label: "Фамилия"
      f.input :role, as: :select, collection: User.roles.keys.map { |role| [ role.humanize, role ] }, label: "Роль"
    end

    f.inputs "Пароль" do
      f.input :password, label: "Пароль"
      f.input :password_confirmation, label: "Подтверждение пароля"
    end
    f.actions
  end

  # Настройка CSV экспорта
  csv do
    column :id
    column :email
    column :first_name
    column :last_name
    column :role
    column :created_at
    column :sign_in_count
  end

  # Контроллер для дополнительной логики
  controller do
    def scoped_collection
      end_of_association_chain
    end

    def create
      super do |format|
        if resource.valid?
          flash[:notice] = "Пользователь #{resource.email} успешно создан с ролью #{resource.display_role}."
        end
      end
    end

    def update
      super do |format|
        if resource.valid?
          flash[:notice] = "Пользователь #{resource.email} успешно обновлен."
        end
      end
    end
  end

  # Batch actions
  batch_action :change_role, form: proc { User.roles.keys.map { |role| [ role.humanize, role ] } } do |ids, inputs|
    role = inputs[:change_role]
    User.where(id: ids).update_all(role: User.roles[role])
    redirect_to collection_path, notice: "Роль изменена для #{ids.count} пользователей на #{role.humanize}"
  end

  # Хелперы для стилизации
  ActiveAdmin.register User do
    controller do
      private

      def role_status_class(role)
        case role
        when "admin"
          :error
        when "promo_manager"
          :warning
        when "shift_leader"
          :ok
        when "support_agent"
          :default
        else
          :default
        end
      end
    end
  end
end

# Хелпер метод для стилизации ролей
def role_status_class(role)
  case role
  when "admin"
    :error
  when "promo_manager"
    :warning
  when "shift_leader"
    :ok
  when "support_agent"
    :default
  else
    :default
  end
end
