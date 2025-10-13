ActiveAdmin.register PermanentBonus do
  permit_params :project, :bonus_id

  index do
    selectable_column
    column :id, &:to_s
    column :project
    column :bonus do |permanent_bonus|
      if permanent_bonus.bonus
        link_to permanent_bonus.bonus.name, admin_bonus_path(permanent_bonus.bonus)
      else
        "Bonus not found (ID: #{permanent_bonus.bonus_id})"
      end
    end
    actions defaults: true do |permanent_bonus|
      item "View Bonus", admin_permanent_bonus_path(permanent_bonus), class: "member_link"
    end
  end

  show do
    attributes_table do
      row :project
      row :bonus do |permanent_bonus|
        permanent_bonus.bonus.name if permanent_bonus.bonus
      end
      row "Bonus Description" do |permanent_bonus|
        permanent_bonus.bonus.description if permanent_bonus.bonus
      end
      # Add other bonus attributes here
    end
  end

  filter :project
  filter :bonus

  form do |f|
    f.inputs do
      f.input :project, as: :select, collection: Bonus.select(:project).distinct.pluck(:project)
      f.input :bonus, as: :select, collection: Bonus.all.map { |b| [b.name, b.id] }
    end
    f.actions
  end
end
