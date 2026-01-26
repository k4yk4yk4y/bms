ActiveAdmin.register HeatmapComment do
  permit_params :date, :body, :user_id

  menu label: "Comments", priority: 45

  filter :date
  filter :user
  filter :body
  filter :created_at

  index do
    selectable_column
    id_column
    column :date
    column :user
    column :body do |comment|
      truncate(comment.body, length: 120)
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :date
      row :user
      row :body
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :date
      f.input :user
      f.input :body
    end
    f.actions
  end
end
