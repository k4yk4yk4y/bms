class MarketingController < ApplicationController
  before_action :set_marketing_request, only: [ :show, :edit, :update, :destroy, :activate, :reject, :transfer ]

  def index
    authorize! :read, MarketingRequest
    @current_tab = params[:tab] || MarketingRequest::REQUEST_TYPES.first

    # Start with base query - filter by manager for marketing_manager
    base_scope = if current_user&.marketing_manager?
                   MarketingRequest.where(manager: current_user.email)
    else
                   MarketingRequest.all
    end

    # Filter by tab only if no search or status filter
    if params[:search].present? || params[:status].present?
      @marketing_requests = base_scope.order(created_at: :desc)
    else
      @marketing_requests = base_scope.by_request_type(@current_tab).order(created_at: :desc)
    end

    # Filter by status if provided
    if params[:status].present? && MarketingRequest::STATUSES.include?(params[:status])
      @marketing_requests = @marketing_requests.by_status(params[:status])
    end

    # Search functionality - optimized with ILIKE for PostgreSQL (case-insensitive)
    if params[:search].present?
      search_term = "%#{params[:search].strip}%"
      @marketing_requests = @marketing_requests.where(
        "promo_code ILIKE ? OR stag ILIKE ? OR manager ILIKE ? OR partner_email ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    # Pagination
    page = [ (params[:page] || 1).to_i, 1 ].max
    per_page = 25
    offset = [ (page - 1) * per_page, 0 ].max

    @total_requests = @marketing_requests.count
    @total_pages = (@total_requests.to_f / per_page).ceil
    @current_page = page
    @marketing_requests = @marketing_requests.limit(per_page).offset(offset)

    # Count tabs based on user scope - optimize with single query
    @tabs = MarketingRequest::REQUEST_TYPES.map do |type|
      count = base_scope.by_request_type(type).count
      {
        key: type,
        label: MarketingRequest::REQUEST_TYPE_LABELS[type],
        count: count
      }
    end
  end

  def show
    authorize! :read, @marketing_request
  end

  def new
    authorize! :create, MarketingRequest
    @marketing_request = MarketingRequest.new
    if params[:request_type].present? && MarketingRequest::REQUEST_TYPES.include?(params[:request_type])
      @marketing_request.request_type = params[:request_type]
    end

    # Автоматически заполняем поле manager email'ом текущего пользователя
    if current_user
      @marketing_request.manager = current_user.email
    end
  end

  def create
    authorize! :create, MarketingRequest
    @marketing_request = MarketingRequest.new(marketing_request_params)

    # Автоматически устанавливаем manager email для marketing_manager
    if current_user
      @marketing_request.manager = current_user.email
    end

    if @marketing_request.save
      redirect_to marketing_index_path(tab: @marketing_request.request_type),
                  notice: "Заявка успешно создана."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize! :update, @marketing_request
  end

  def update
    authorize! :update, @marketing_request

    if @marketing_request.update(marketing_request_params)
      redirect_to marketing_index_path(tab: @marketing_request.request_type),
                  notice: "Заявка успешно обновлена."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize! :destroy, @marketing_request
    tab = @marketing_request.request_type
    @marketing_request.destroy
    redirect_to marketing_index_path(tab: tab),
                notice: "Заявка успешно удалена."
  end

  def activate
    authorize! :activate, @marketing_request

    if @marketing_request.activate!
      redirect_to marketing_index_path(tab: @marketing_request.request_type),
                  notice: "Заявка активирована."
    else
      redirect_to marketing_path(@marketing_request),
                  alert: "Ошибка при активации: #{@marketing_request.errors.full_messages.join(', ')}"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to marketing_path(@marketing_request),
                alert: "Ошибка при активации: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    Rails.logger.error "Marketing activation error: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    redirect_to marketing_path(@marketing_request),
                alert: "Ошибка при активации: #{e.message}"
  end

  def reject
    authorize! :reject, @marketing_request

    if @marketing_request.reject!
      redirect_to marketing_index_path(tab: @marketing_request.request_type),
                  notice: "Заявка отклонена."
    else
      redirect_to marketing_path(@marketing_request),
                  alert: "Ошибка при отклонении: #{@marketing_request.errors.full_messages.join(', ')}"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to marketing_path(@marketing_request),
                alert: "Ошибка при отклонении: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    Rails.logger.error "Marketing rejection error: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    redirect_to marketing_path(@marketing_request),
                alert: "Ошибка при отклонении: #{e.message}"
  end

  def transfer
    authorize! :transfer, @marketing_request
    new_request_type = params[:new_request_type]

    unless MarketingRequest::REQUEST_TYPES.include?(new_request_type)
      redirect_to marketing_path(@marketing_request),
                  alert: "Неверный тип заявки для переноса."
      return
    end

    old_type = @marketing_request.request_type_label

    if @marketing_request.update(
      request_type: new_request_type,
      status: "pending",  # Всегда возвращаем в pending при переносе
      activation_date: nil
    )
      redirect_to marketing_index_path(tab: new_request_type),
                  notice: "Заявка перенесена из \"#{old_type}\" в \"#{@marketing_request.request_type_label}\"."
    else
      redirect_to marketing_path(@marketing_request),
                  alert: "Ошибка при переносе: #{@marketing_request.errors.full_messages.join(', ')}"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to marketing_path(@marketing_request),
                alert: "Ошибка при переносе: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    Rails.logger.error "Marketing transfer error: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    redirect_to marketing_path(@marketing_request),
                alert: "Ошибка при переносе: #{e.message}"
  end

  private

  def set_marketing_request
    @marketing_request = MarketingRequest.find(params[:id])
  end

  def marketing_request_params
    permitted = params.require(:marketing_request).permit(
      :platform, :partner_email, :promo_code,
      :stag, :activation_date, :status, :request_type
    )

    # Only allow status and activation_date changes for admins
    unless current_user&.admin?
      permitted.delete(:status)
      permitted.delete(:activation_date)
    end

    permitted
  end
end
