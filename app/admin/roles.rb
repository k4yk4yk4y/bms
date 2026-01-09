ActiveAdmin.register Role do
  permit_params :key, :name, permissions: Role.section_keys

  menu priority: 30, label: "Roles"

  index do
    selectable_column
    id_column
    column :key
    column :name
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
    end
    f.inputs "Доступы" do
      Role::SECTION_DEFINITIONS.each do |section|
        f.input section[:key],
          label: section[:label],
          as: :select,
          collection: Role.permission_level_options,
          selected: f.object.permission_level_for(section[:key]),
          input_html: { name: "role[permissions][#{section[:key]}]" }
      end
    end
    f.actions
  end
end
