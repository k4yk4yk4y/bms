ActiveAdmin.register_page "Projects" do
  content do
    panel "Projects" do
      table_for Bonus.select(:project).distinct.pluck(:project) do
        column :project do |project|
          link_to project, admin_permanent_bonuses_path(q: { project_eq: project }) # This is a temporary link, will be improved
        end
      end
    end
  end
end
