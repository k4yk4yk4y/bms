ActiveAdmin.register Project do
  # Application Settings - Projects Management
  menu label: "Projects", parent: "Application Settings", priority: 90

  permit_params :name, :currencies

  index do
    selectable_column
    column :id
    column :name
    column :currencies do |project|
      project.formatted_currencies
    end
    column :permanent_bonuses_count do |project|
      project.permanent_bonuses.count
    end
    column :created_at
    column :updated_at
    actions
  end

  filter :name
  filter :created_at
  filter :updated_at

  form do |f|
    project = f.object
    f.inputs do
      f.input :name, hint: "Unique project name"
      f.input :currencies,
              as: :project_currencies,
              hint: "Enter ISO currency codes separated by ';'."
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :currencies do |project|
        project.formatted_currencies
      end
      row :created_at
      row :updated_at
    end

    panel "Permanent Bonuses" do
      table_for project.permanent_bonuses do
        column :bonus do |pb|
          link_to pb.bonus.name, admin_bonus_path(pb.bonus) if pb.bonus
        end
        column :created_at
        column "Actions" do |pb|
          link_to "View", admin_permanent_bonus_path(pb)
        end
      end
    end
  end
end
