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

  filter :project, as: :select, collection: -> { Project.all.map { |p| [ p.name, p.id ] } }
  filter :bonus, as: :select, collection: -> { Bonus.all.map { |b| [ b.name, b.id ] } }
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :project_id, as: :select,
              collection: Project.all.map { |p| [ p.name, p.id ] },
              include_blank: false,
              label: "Project",
              hint: "Select the project first, then choose a bonus",
              input_html: { id: "permanent_bonus_project_id", class: "project-selector" }

      # Show all bonuses with project prefix and ID
      bonus_options = Bonus.all
                           .order(:project, :name)
                           .map do |b|
                             # Format: "PROJECT - #ID: Bonus Name"
                             [ "#{b.project} - ##{b.id}: #{b.name}", b.id, { 'data-project': b.project } ]
                           end

      f.input :bonus_id, as: :select,
              collection: bonus_options,
              include_blank: false,
              label: "Bonus",
              hint: "Bonuses will be filtered based on selected project",
              input_html: { id: "permanent_bonus_bonus_id", class: "bonus-selector" }

      # Add inline JavaScript for dynamic filtering
      li class: "hidden" do
        content_tag :script do
          raw <<~JS
            (function() {
              const projectSelect = document.getElementById('permanent_bonus_project_id');
              const bonusSelect = document.getElementById('permanent_bonus_bonus_id');
            #{'  '}
              if (projectSelect && bonusSelect) {
                const allBonusOptions = Array.from(bonusSelect.options).map(option => ({
                  value: option.value,
                  text: option.text,
                  project: option.text.split(' - ')[0]
                }));
            #{'    '}
                function filterBonuses() {
                  const selectedProjectId = projectSelect.value;
                  if (!selectedProjectId) return;
            #{'      '}
                  const projectName = projectSelect.options[projectSelect.selectedIndex].text;
                  bonusSelect.innerHTML = '';
            #{'      '}
                  const matchingBonuses = allBonusOptions.filter(opt => opt.project === projectName);
            #{'      '}
                  const bonusesToShow = matchingBonuses.length > 0 ? matchingBonuses : allBonusOptions;
                  bonusesToShow.forEach(option => {
                    const opt = document.createElement('option');
                    opt.value = option.value;
                    opt.text = option.text;
                    bonusSelect.add(opt);
                  });
                }
            #{'    '}
                projectSelect.addEventListener('change', filterBonuses);
            #{'    '}
                if (projectSelect.value) {
                  setTimeout(filterBonuses, 100);
                }
              }
            })();
          JS
        end
      end
    end
    f.actions
  end

  # Add JavaScript for dynamic filtering
  controller do
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
