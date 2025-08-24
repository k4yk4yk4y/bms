class MarketingController < ApplicationController
  before_action :set_marketing_request, only: [ :show, :edit, :update, :destroy, :activate, :reject, :transfer ]

  def index
    authorize! :read, MarketingRequest
    @current_tab = params[:tab] || MarketingRequest::REQUEST_TYPES.first

    # Start with base query - filter by tab only if no search or status filter
    if params[:search].present? || params[:status].present?
      @marketing_requests = MarketingRequest.all.order(:created_at)
    else
      @marketing_requests = MarketingRequest.by_request_type(@current_tab).order(:created_at)
    end

    # Filter by status if provided
    if params[:status].present? && MarketingRequest::STATUSES.include?(params[:status])
      @marketing_requests = @marketing_requests.by_status(params[:status])
    end

    # Search functionality
    if params[:search].present?
      search_term = params[:search].strip.downcase
      @marketing_requests = @marketing_requests.where(
        "LOWER(promo_code) LIKE ? OR LOWER(stag) LIKE ? OR LOWER(manager) LIKE ? OR LOWER(partner_email) LIKE ?",
        "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%"
      )
    end

    @tabs = MarketingRequest::REQUEST_TYPES.map do |type|
      {
        key: type,
        label: MarketingRequest::REQUEST_TYPE_LABELS[type],
        count: MarketingRequest.by_request_type(type).count
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
  end

  def create
    authorize! :create, MarketingRequest
    @marketing_request = MarketingRequest.new(marketing_request_params)

    if @marketing_request.save
      redirect_to marketing_index_path(tab: @marketing_request.request_type),
                  notice: "Заявка успешно создана."
    else
      render :new, status: :unprocessable_entity
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
      render :edit, status: :unprocessable_entity
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
    @marketing_request.activate!
    redirect_to marketing_index_path(tab: @marketing_request.request_type),
                notice: "Заявка активирована."
  rescue => e
    redirect_to marketing_index_path(tab: @marketing_request.request_type),
                alert: "Ошибка при активации: #{e.message}"
  end

  def reject
    authorize! :reject, @marketing_request
    @marketing_request.reject!
    redirect_to marketing_index_path(tab: @marketing_request.request_type),
                notice: "Заявка отклонена."
  rescue => e
    redirect_to marketing_index_path(tab: @marketing_request.request_type),
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
    old_request_type = @marketing_request.request_type

    @marketing_request.update!(
      request_type: new_request_type,
      status: "pending",  # Всегда возвращаем в pending при переносе
      activation_date: nil
    )

    redirect_to marketing_index_path(tab: new_request_type),
                notice: "Заявка перенесена из \"#{old_type}\" в \"#{@marketing_request.request_type_label}\"."
  rescue => e
    redirect_to marketing_path(@marketing_request),
                alert: "Ошибка при переносе: #{e.message}"
  end

  private

  def set_marketing_request
    @marketing_request = MarketingRequest.find(params[:id])
  end

  def marketing_request_params
    params.require(:marketing_request).permit(
      :manager, :platform, :partner_email, :promo_code,
      :stag, :activation_date, :status, :request_type
    )
  end
end
