ActiveAdmin.register_page "DSL Tags" do
  # Application Settings - DSL Tags Management
  menu label: "DSL Tags", parent: "Application Settings", priority: 3

  content title: "DSL Tags Management" do
    # Получаем все уникальные DSL теги с статистикой
    dsl_tags_data = BonusTemplate.group(:dsl_tag)
                                 .select("dsl_tag, COUNT(*) as usage_count, 
                                         COUNT(DISTINCT project) as projects_count,
                                         MIN(created_at) as first_used,
                                         MAX(updated_at) as last_updated")
                                 .order(:dsl_tag)

    # Основная информация
    div class: "panel" do
      h3 "DSL Tags Overview"
      para "Управление DSL тегами для шаблонов бонусов. DSL теги используются для идентификации и группировки шаблонов бонусов."
    end

    # Статистика
    div class: "panel" do
      h3 "Статистика"
      div class: "stats_grid" do
        div class: "stat_item" do
          h4 dsl_tags_data.count
          p "Всего DSL тегов"
        end
        div class: "stat_item" do
          h4 BonusTemplate.count
          p "Всего шаблонов"
        end
        div class: "stat_item" do
          h4 Project.count
          p "Всего проектов"
        end
      end
    end

    # Таблица DSL тегов
    div class: "panel" do
      h3 "Все DSL теги"
      
      if dsl_tags_data.any?
        table class: "index_table" do
          thead do
            tr do
              th "DSL Tag"
              th "Использований"
              th "Проектов"
              th "Первый раз использован"
              th "Последнее обновление"
              th "Действия"
            end
          end
          tbody do
            dsl_tags_data.each do |tag_data|
              tr do
                td do
                  status_tag tag_data.dsl_tag, class: :info
                end
                td do
                  strong tag_data.usage_count
                end
                td do
                  strong tag_data.projects_count
                end
                td do
                  tag_data.first_used&.strftime("%d.%m.%Y %H:%M")
                end
                td do
                  tag_data.last_updated&.strftime("%d.%m.%Y %H:%M")
                end
                td do
                  div class: "action_items" do
                    link_to "Просмотр", "#", 
                            class: "member_link", 
                            onclick: "showTagDetails('#{tag_data.dsl_tag}')"
                    link_to "Переименовать", "#", 
                            class: "member_link", 
                            onclick: "renameTag('#{tag_data.dsl_tag}')"
                    if tag_data.usage_count == 0
                      link_to "Удалить", "#", 
                              class: "member_link delete_link", 
                              onclick: "deleteTag('#{tag_data.dsl_tag}')"
                    end
                  end
                end
              end
            end
          end
        end
      else
        div class: "blank_slate_container" do
          span class: "blank_slate" do
            span "Нет DSL тегов"
          end
        end
      end
    end

    # Детали тега (скрытая панель)
    div id: "tag_details_panel", style: "display: none;" do
      div class: "panel" do
        h3 "Детали DSL тега: "
        span id: "tag_name_display"
        
        div id: "tag_details_content" do
          # Контент будет загружен через AJAX
        end
      end
    end

    # Форма переименования тега (скрытая)
    div id: "rename_tag_modal", style: "display: none;" do
      div class: "modal" do
        div class: "modal_content" do
          h3 "Переименовать DSL тег"
          form id: "rename_tag_form" do
            input type: "hidden", id: "current_tag_name"
            div class: "form_field" do
              label "Новое имя тега:"
              input type: "text", id: "new_tag_name", required: true
            end
            div class: "form_actions" do
              button type: "submit", class: "button primary" do
                "Переименовать"
              end
              button type: "button", onclick: "closeRenameModal()", class: "button" do
                "Отмена"
              end
            end
          end
        end
      end
    end
  end

  # JavaScript для интерактивности
  page_action :tag_details, method: :get do
    tag_name = params[:tag_name]
    templates = BonusTemplate.where(dsl_tag: tag_name).includes(:project)
    
    render json: {
      tag_name: tag_name,
      templates_count: templates.count,
      projects: templates.pluck(:project).uniq,
      templates: templates.map do |template|
        {
          id: template.id,
          name: template.name,
          project: template.project,
          event: template.event,
          created_at: template.created_at.strftime("%d.%m.%Y %H:%M")
        }
      end
    }
  end

  page_action :rename_tag, method: :post do
    old_tag = params[:old_tag]
    new_tag = params[:new_tag]
    
    begin
      # Проверяем, что новый тег не существует
      if BonusTemplate.where(dsl_tag: new_tag).exists?
        render json: { success: false, error: "DSL тег '#{new_tag}' уже существует" }
        return
      end
      
      # Переименовываем все шаблоны с этим тегом
      updated_count = BonusTemplate.where(dsl_tag: old_tag).update_all(dsl_tag: new_tag)
      
      render json: { 
        success: true, 
        message: "DSL тег успешно переименован. Обновлено #{updated_count} шаблонов." 
      }
    rescue => e
      render json: { success: false, error: e.message }
    end
  end

  page_action :delete_tag, method: :delete do
    tag_name = params[:tag_name]
    
    begin
      # Проверяем, что тег не используется
      if BonusTemplate.where(dsl_tag: tag_name).exists?
        render json: { success: false, error: "DSL тег используется в шаблонах и не может быть удален" }
        return
      end
      
      render json: { 
        success: true, 
        message: "DSL тег '#{tag_name}' удален (не использовался)" 
      }
    rescue => e
      render json: { success: false, error: e.message }
    end
  end
end

# CSS стили для DSL Tags страницы
content_for :head do
  style do
    raw <<~CSS
      .stats_grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 20px;
        margin: 20px 0;
      }
      
      .stat_item {
        text-align: center;
        padding: 20px;
        background: #f8f9fa;
        border-radius: 8px;
        border: 1px solid #e9ecef;
      }
      
      .stat_item h4 {
        font-size: 2em;
        margin: 0;
        color: #007bff;
      }
      
      .stat_item p {
        margin: 5px 0 0 0;
        color: #6c757d;
      }
      
      .modal {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0,0,0,0.5);
        z-index: 1000;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      
      .modal_content {
        background: white;
        padding: 30px;
        border-radius: 8px;
        max-width: 500px;
        width: 90%;
      }
      
      .form_field {
        margin: 15px 0;
      }
      
      .form_field label {
        display: block;
        margin-bottom: 5px;
        font-weight: bold;
      }
      
      .form_field input {
        width: 100%;
        padding: 8px;
        border: 1px solid #ddd;
        border-radius: 4px;
      }
      
      .form_actions {
        margin-top: 20px;
        text-align: right;
      }
      
      .action_items {
        display: flex;
        gap: 10px;
      }
      
      .delete_link {
        color: #dc3545 !important;
      }
    CSS
  end
end

# JavaScript для интерактивности
content_for :footer do
  script do
    raw <<~JS
      function showTagDetails(tagName) {
        fetch(`/admin/dsl_tags/tag_details?tag_name=${encodeURIComponent(tagName)}`)
          .then(response => response.json())
          .then(data => {
            document.getElementById('tag_name_display').textContent = data.tag_name;
            document.getElementById('tag_details_content').innerHTML = `
              <p><strong>Количество шаблонов:</strong> ${data.templates_count}</p>
              <p><strong>Проекты:</strong> ${data.projects.join(', ')}</p>
              <h4>Шаблоны:</h4>
              <table class="index_table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Название</th>
                    <th>Проект</th>
                    <th>Событие</th>
                    <th>Создан</th>
                  </tr>
                </thead>
                <tbody>
                  ${data.templates.map(template => `
                    <tr>
                      <td>${template.id}</td>
                      <td>${template.name}</td>
                      <td>${template.project}</td>
                      <td>${template.event}</td>
                      <td>${template.created_at}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            `;
            document.getElementById('tag_details_panel').style.display = 'block';
          })
          .catch(error => {
            alert('Ошибка при загрузке деталей тега: ' + error.message);
          });
      }
      
      function renameTag(tagName) {
        document.getElementById('current_tag_name').value = tagName;
        document.getElementById('new_tag_name').value = tagName;
        document.getElementById('rename_tag_modal').style.display = 'block';
      }
      
      function closeRenameModal() {
        document.getElementById('rename_tag_modal').style.display = 'none';
      }
      
      function deleteTag(tagName) {
        if (confirm(`Вы уверены, что хотите удалить DSL тег "${tagName}"?`)) {
          fetch(`/admin/dsl_tags/delete_tag`, {
            method: 'DELETE',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            },
            body: JSON.stringify({ tag_name: tagName })
          })
          .then(response => response.json())
          .then(data => {
            if (data.success) {
              alert(data.message);
              location.reload();
            } else {
              alert('Ошибка: ' + data.error);
            }
          })
          .catch(error => {
            alert('Ошибка при удалении тега: ' + error.message);
          });
        }
      }
      
      document.getElementById('rename_tag_form').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const oldTag = document.getElementById('current_tag_name').value;
        const newTag = document.getElementById('new_tag_name').value;
        
        if (oldTag === newTag) {
          alert('Новое имя должно отличаться от текущего');
          return;
        }
        
        fetch(`/admin/dsl_tags/rename_tag`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          },
          body: JSON.stringify({ old_tag: oldTag, new_tag: newTag })
        })
        .then(response => response.json())
        .then(data => {
          if (data.success) {
            alert(data.message);
            location.reload();
          } else {
            alert('Ошибка: ' + data.error);
          }
        })
        .catch(error => {
          alert('Ошибка при переименовании тега: ' + error.message);
        });
      });
    JS
  end
end
