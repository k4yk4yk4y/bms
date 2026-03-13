ActiveAdmin.register AdminUser do
  menu priority: 31

  permit_params :email, :password, :password_confirmation, :admin_role_id

  index do
    selectable_column
    column :id
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :admin_role
    column :created_at
    actions
  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :admin_role
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :admin_role, as: :select, collection: AdminRole.order(:name)
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  controller do
    before_action :allow_update_without_password, only: :update

    private

    # Devise treats empty password fields as a password update attempt.
    # Remove them on edit when both are blank.
    def allow_update_without_password
      return unless params[:admin_user]
      return unless params[:admin_user][:password].blank? && params[:admin_user][:password_confirmation].blank?

      params[:admin_user].delete(:password)
      params[:admin_user].delete(:password_confirmation)
    end
  end
end
