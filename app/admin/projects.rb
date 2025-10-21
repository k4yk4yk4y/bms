ActiveAdmin.register Project do
  # Application Settings - Projects Management
  menu label: "Projects", parent: "Application Settings", priority: 1
  
  permit_params :name

  index do
    selectable_column
    column :id
    column :name
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
    f.inputs do
      f.input :name, hint: "Unique project name"
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
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
