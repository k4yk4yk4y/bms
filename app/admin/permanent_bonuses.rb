ActiveAdmin.register PermanentBonus do
  menu priority: 11

  permit_params :project_id, :bonus_id

  index do
    selectable_column
    column :id
    column :project do |permanent_bonus|
      if permanent_bonus.project
        link_to permanent_bonus.project.name, admin_project_path(permanent_bonus.project)
      else
        "Project not found"
      end
    end
    column :bonus do |permanent_bonus|
      if permanent_bonus.bonus
        link_to permanent_bonus.bonus.name, admin_bonus_path(permanent_bonus.bonus)
      else
        "Bonus not found (ID: #{permanent_bonus.bonus_id})"
      end
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :project do |permanent_bonus|
        link_to permanent_bonus.project.name, admin_project_path(permanent_bonus.project) if permanent_bonus.project
      end
      row :bonus do |permanent_bonus|
        link_to permanent_bonus.bonus.name, admin_bonus_path(permanent_bonus.bonus) if permanent_bonus.bonus
      end
      row "Bonus Description" do |permanent_bonus|
        permanent_bonus.bonus.description if permanent_bonus.bonus
      end
      row :created_at
      row :updated_at
    end
  end

  filter :project, as: :select, collection: -> { Project.order(:name).pluck(:name, :id) }
  filter :bonus, as: :select, collection: -> { Bonus.order(:name).limit(200).pluck(:name, :id) }
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      selected_project = f.object.project
      selected_project_name = selected_project&.name

      f.input :project_id, as: :select,
              collection: Project.order(:name).pluck(:name, :id),
              include_blank: false,
              label: "Project",
              hint: "Select the project first, then choose a bonus",
              input_html: { id: "permanent_bonus_project_id", class: "project-selector" }

      bonus_scope = if selected_project_name.present?
                      Bonus.where(project: selected_project_name)
      else
                      Bonus.none
      end

      bonus_options = bonus_scope.order(id: :desc).limit(500).pluck(:id, :name, :project).map do |id, name, project|
        [ "#{project} - ##{id}: #{name}", id ]
      end

      f.input :bonus_id, as: :select,
              collection: bonus_options,
              include_blank: false,
              label: "Bonus",
              hint: "Bonuses will be filtered based on selected project",
              input_html: {
                id: "permanent_bonus_bonus_id",
                class: "bonus-selector",
                data: { selected_bonus_id: f.object.bonus_id }
              }

      li class: "hidden" do
        content_tag :script do
          raw <<~JS
            (function() {
              const projectSelect = document.getElementById('permanent_bonus_project_id');
              const bonusSelect = document.getElementById('permanent_bonus_bonus_id');

              if (!projectSelect || !bonusSelect) return;

              async function loadBonuses(projectId, selectedBonusId) {
                if (!projectId) {
                  bonusSelect.innerHTML = '';
                  return;
                }

                try {
                  const response = await fetch(`/admin/permanent_bonuses/bonuses_for_project?project_id=${encodeURIComponent(projectId)}`, {
                    headers: { 'Accept': 'application/json' }
                  });
                  if (!response.ok) return;

                  const options = await response.json();
                  bonusSelect.innerHTML = '';
                  options.forEach(({ id, label }) => {
                    const opt = document.createElement('option');
                    opt.value = String(id);
                    opt.text = label;
                    bonusSelect.add(opt);
                  });

                  if (selectedBonusId) {
                    bonusSelect.value = String(selectedBonusId);
                  }
                } catch (_) {
                  // no-op
                }
              }

              projectSelect.addEventListener('change', () => {
                loadBonuses(projectSelect.value, null);
              });

              if (projectSelect.value) {
                loadBonuses(projectSelect.value, bonusSelect.dataset.selectedBonusId);
              }
            })();
          JS
        end
      end
    end
    f.actions
  end

  collection_action :bonuses_for_project, method: :get do
    project = Project.find_by(id: params[:project_id])
    bonuses = if project
      Bonus.where(project: project.name).order(id: :desc).limit(500).pluck(:id, :name, :project)
    else
      []
    end

    render json: bonuses.map { |id, name, project_name| { id: id, label: "#{project_name} - ##{id}: #{name}" } }
  end

  controller do
    def scoped_collection
      super.includes(:project, :bonus)
    end

    def new
      @page_title = "New Permanent Bonus"
      new!
    end

    def edit
      @page_title = "Edit Permanent Bonus"
      edit!
    end
  end
end
