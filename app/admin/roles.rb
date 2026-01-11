ActiveAdmin.register Role do
  permit_params :key, :name, :admin_panel_access, permissions: Role.section_keys

  menu priority: 40, label: "Roles"

  index do
    selectable_column
    id_column
    column :key
    column :name
    column :admin_panel_access
    column "Доступы" do |role|
      role.permissions_summary
    end
    actions
  end

  show do
    attributes_table do
      row :key
      row :name
      row :permissions do |role|
        ul do
          role.permissions.to_h.each do |section_key, level|
            li "#{Role.section_label(section_key)}: #{Role::PERMISSION_LEVEL_LABELS[level] || level}"
          end
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Основное" do
      f.input :key, as: :select, collection: User.roles.keys.map { |role| [ role.humanize, role ] }
      f.input :name
      f.input :admin_panel_access, as: :boolean, label: "Доступ в ActiveAdmin"
    end
    f.inputs "Доступы" do
      Role::SECTION_DEFINITIONS.each do |section|
        f.input section[:key],
          label: section[:label],
          as: :select,
          collection: Role.permission_level_options,
          selected: f.object.permission_level_for(section[:key]),
          hint: Role.section_hint(section[:key]),
          input_html: { name: "role[permissions][#{section[:key]}]" }
      end
    end
    f.actions
  end
end
