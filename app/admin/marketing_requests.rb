ActiveAdmin.register MarketingRequest do
  menu priority: 5, label: "Marketing Requests", parent: false

  permit_params :manager, :platform, :partner_email, :promo_code, :stag,
                :status, :request_type, :activation_date

  # Scopes for quick filtering
  scope :all, default: true
  scope :pending
  scope :activated
  scope :rejected

  # Filters
  filter :manager
  filter :partner_email
  filter :stag
  filter :promo_code
  filter :status, as: :select, collection: MarketingRequest::STATUSES.map { |s| [ MarketingRequest::STATUS_LABELS[s], s ] }
  filter :request_type, as: :select, collection: MarketingRequest::REQUEST_TYPES.map { |t| [ MarketingRequest::REQUEST_TYPE_LABELS[t], t ] }
  filter :activation_date
  filter :created_at
  filter :updated_at

  # Index page configuration
  index do
    selectable_column
    id_column

    column :manager
    column :request_type do |request|
      status_tag request.request_type_label, class: :info
    end
    column :partner_email do |request|
      mail_to request.partner_email, request.partner_email
    end
    column :promo_code do |request|
      codes = request.promo_codes_array
      if codes.length == 1
        content_tag(:code, codes.first, class: "bg-light px-2 py-1 rounded")
      else
        content_tag(:div) do
          codes.map { |code| content_tag(:code, code, class: "bg-light px-1 py-1 rounded small me-1") }.join.html_safe +
          content_tag(:small, "(#{codes.length} кодов)", class: "text-muted")
        end
      end
    end
    column :stag do |request|
      content_tag(:code, request.stag, class: "bg-light px-2 py-1 rounded")
    end
    column :status do |request|
      status_class = case request.status
      when "pending"
        :warning
      when "activated"
        :ok
      when "rejected"
        :error
      else
        :default
      end
      status_tag request.status_label, class: status_class
    end
    column :activation_date
    column :created_at

    actions defaults: true do |request|
      if request.pending?
        item "Активировать", activate_admin_marketing_request_path(request),
             method: :patch, class: "member_link"
        item "Отклонить", reject_admin_marketing_request_path(request),
             method: :patch, class: "member_link"
      end
    end
  end

  # Show page configuration
  show do
    attributes_table do
      row :id
      row :manager
      row :request_type do |request|
        status_tag request.request_type_label, class: :info
      end
      row :status do |request|
        status_class = case request.status
        when "pending"
          :warning
        when "activated"
          :ok
        when "rejected"
          :error
        else
          :default
        end
        status_tag request.status_label, class: status_class
      end
      row :platform do |request|
        if request.platform.present?
          if request.platform.match?(URI::DEFAULT_PARSER.make_regexp)
            link_to request.platform, request.platform, target: "_blank"
          else
            simple_format(request.platform)
          end
        else
          "—"
        end
      end
      row :partner_email do |request|
        mail_to request.partner_email, request.partner_email
      end
      row :promo_code do |request|
        codes = request.promo_codes_array
        if codes.length == 1
          content_tag(:code, codes.first, class: "bg-light px-3 py-2 rounded fs-5")
        else
          content_tag(:div) do
            codes.map { |code|
              content_tag(:div, class: "mb-1") do
                content_tag(:code, code, class: "bg-light px-2 py-1 rounded me-2")
              end
            }.join.html_safe +
            content_tag(:small, "Всего кодов: #{codes.length}", class: "text-muted")
          end
        end
      end
      row :stag do |request|
        content_tag(:code, request.stag, class: "bg-light px-3 py-2 rounded fs-5")
      end
      row :activation_date
      row :created_at
      row :updated_at
    end

    # Warning if partner has other requests
    if marketing_request.has_existing_partner_request?
      panel "Предупреждение" do
        existing_request = marketing_request.existing_partner_request
        div class: "alert alert-warning" do
          "Для этого партнера (STAG: #{marketing_request.stag}) уже существует другая заявка: " +
          link_to("#{existing_request.request_type_label} ##{existing_request.id}",
                  admin_marketing_request_path(existing_request)) +
          " (статус: #{existing_request.status_label})"
        end
      end
    end
  end

  # Form configuration
  form do |f|
    f.inputs "Основная информация" do
      f.input :manager, hint: "Email менеджера (должен быть валидным email)"
      f.input :request_type, as: :select,
              collection: MarketingRequest::REQUEST_TYPES.map { |t| [ MarketingRequest::REQUEST_TYPE_LABELS[t], t ] },
              include_blank: false
      f.input :status, as: :select,
              collection: MarketingRequest::STATUSES.map { |s| [ MarketingRequest::STATUS_LABELS[s], s ] },
              include_blank: false
    end

    f.inputs "Информация о партнере" do
      f.input :partner_email, hint: "Email партнёра"
      f.input :stag, hint: "Уникальный идентификатор партнёра (без пробелов)"
      f.input :platform, as: :text, hint: "Ссылка на площадку или описание", input_html: { rows: 3 }
    end

    f.inputs "Промокоды" do
      f.input :promo_code, as: :text, hint: "Несколько кодов разделяйте запятыми или новыми строками. Разрешены только буквы, цифры и подчеркивания.", input_html: { rows: 3, style: "text-transform: uppercase;" }
    end

    f.inputs "Активация" do
      f.input :activation_date, as: :datetime_local, hint: "Устанавливается автоматически при активации"
    end

    f.actions
  end

  # Member actions
  member_action :activate, method: :patch do
    resource.activate!
    redirect_to admin_marketing_request_path(resource), notice: "Заявка активирована."
  rescue => e
    redirect_to admin_marketing_request_path(resource), alert: "Ошибка при активации: #{e.message}"
  end

  member_action :reject, method: :patch do
    resource.reject!
    redirect_to admin_marketing_request_path(resource), notice: "Заявка отклонена."
  rescue => e
    redirect_to admin_marketing_request_path(resource), alert: "Ошибка при отклонении: #{e.message}"
  end

  # Batch actions
  batch_action :activate, confirm: "Активировать выбранные заявки?" do |ids|
    MarketingRequest.where(id: ids).find_each do |request|
      request.activate! if request.pending?
    end
    redirect_to collection_path, notice: "Заявки активированы."
  end

  batch_action :reject, confirm: "Отклонить выбранные заявки?" do |ids|
    MarketingRequest.where(id: ids).find_each do |request|
      request.reject! if request.pending?
    end
    redirect_to collection_path, notice: "Заявки отклонены."
  end

  # CSV export
  csv do
    column :id
    column :manager
    column :request_type
    column :status
    column :partner_email
    column :promo_code
    column :stag
    column :platform
    column :activation_date
    column :created_at
    column :updated_at
  end

  # Controller customization
  controller do
    def scoped_collection
      super
    end
  end
end
