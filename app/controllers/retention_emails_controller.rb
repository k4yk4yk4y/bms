class RetentionEmailsController < ApplicationController
  before_action :set_retention_chain
  before_action :set_retention_email, only: [ :show, :edit, :update, :destroy ]

  def show
    authorize! :read, @retention_email
  end

  def new
    authorize! :create, RetentionEmail
    @retention_email = @retention_chain.retention_emails.new(status: "draft")
    @selected_bonuses = @retention_email.bonuses
  end

  def create
    authorize! :create, RetentionEmail
    @retention_email = @retention_chain.retention_emails.new(retention_email_params)

    if @retention_email.save
      respond_to do |format|
        format.html do
          redirect_to retention_chain_retention_email_path(@retention_chain, @retention_email),
                      notice: "Retention email created."
        end
        format.json { render json: autosave_payload(@retention_email), status: :created }
      end
    else
      @selected_bonuses = @retention_email.bonuses
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { errors: @retention_email.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def edit
    authorize! :update, @retention_email
    @selected_bonuses = @retention_email.bonuses
  end

  def update
    authorize! :update, @retention_email

    if @retention_email.update(retention_email_params)
      respond_to do |format|
        format.html do
          redirect_to retention_chain_retention_email_path(@retention_chain, @retention_email),
                      notice: "Retention email updated."
        end
        format.json { render json: autosave_payload(@retention_email), status: :ok }
      end
    else
      @selected_bonuses = @retention_email.bonuses
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: { errors: @retention_email.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize! :destroy, @retention_email
    @retention_email.destroy
    redirect_to retention_chain_path(@retention_chain), notice: "Retention email deleted."
  end

  def destroy_image
    authorize! :update, @retention_email
    attachment = @retention_email.images.attachments.find(params[:attachment_id])
    attachment.purge
    redirect_back fallback_location: edit_retention_chain_retention_email_path(@retention_chain, @retention_email),
                  notice: "Image removed."
  end

  def reorder
    authorize! :update, RetentionEmail
    order = params[:order].to_a.map(&:to_i)

    ActiveRecord::Base.transaction do
      order.each_with_index do |id, index|
        email = @retention_chain.retention_emails.find_by(id: id)
        next unless email

        email.update!(position: index + 1)
      end
    end

    head :ok
  end

  private

  def set_retention_chain
    @retention_chain = RetentionChain.find(params[:retention_chain_id])
  end

  def set_retention_email
    @retention_email = @retention_chain.retention_emails.find(params[:id])
  end

  def retention_email_params
    params.require(:retention_email).permit(
      :subject,
      :preheader,
      :header,
      :body,
      :send_timing,
      :description,
      :status,
      :launch_date,
      bonus_ids: [],
      images: []
    )
  end

  def autosave_payload(retention_email)
    {
      id: retention_email.id,
      edit_url: edit_retention_chain_retention_email_path(@retention_chain, retention_email),
      update_url: retention_chain_retention_email_path(@retention_chain, retention_email),
      updated_at: retention_email.updated_at
    }
  end
end
