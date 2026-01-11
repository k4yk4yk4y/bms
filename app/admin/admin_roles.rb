ActiveAdmin.register AdminRole do
  permit_params :key, :name, permissions: AdminRole.section_keys

  menu priority: 41, label: "Admin roles"

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
            li "#{AdminRole.section_label(section_key)}: #{AdminRole::PERMISSION_LEVEL_LABELS[level] || level}"
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
      f.input :key
      f.input :name
    end
    f.inputs "Доступы" do
      AdminRole::SECTION_DEFINITIONS.each do |section|
        f.input section[:key],
          label: section[:label],
          as: :select,
          collection: AdminRole.permission_level_options,
          selected: f.object.permission_level_for(section[:key]),
          hint: AdminRole.section_hint(section[:key]),
          input_html: { name: "admin_role[permissions][#{section[:key]}]" }
      end
    end
    f.actions
  end
end
