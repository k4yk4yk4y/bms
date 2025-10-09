class SetupController < ApplicationController
  # Отключаем аутентификацию для setup страницы
  skip_before_action :authenticate_user!, only: [:index, :create_admin]
  skip_before_action :verify_authenticity_token, only: [:create_admin]
  
  def index
    # Проверяем, есть ли уже админы
    @has_admin = User.where(role: :admin).exists?
    @admin_count = User.where(role: :admin).count
    
    # Если админ уже есть, перенаправляем на главную
    if @has_admin
      redirect_to root_path, notice: 'Admin user already exists. Please log in.'
    end
  end

  def create_admin
    # Проверяем, есть ли уже админы
    if User.where(role: :admin).exists?
      redirect_to setup_index_path, alert: 'Admin user already exists!'
      return
    end

    # Параметры из формы
    email = params[:email]
    password = params[:password]
    password_confirmation = params[:password_confirmation]
    first_name = params[:first_name]
    last_name = params[:last_name]

    # Валидация
    if password != password_confirmation
      redirect_to setup_index_path, alert: 'Passwords do not match!'
      return
    end

    if password.blank? || password.length < 6
      redirect_to setup_index_path, alert: 'Password must be at least 6 characters long!'
      return
    end

    begin
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password_confirmation,
        first_name: first_name,
        last_name: last_name,
        role: :admin
      )

      redirect_to root_path, notice: "Admin user created successfully! Email: #{user.email}"
    rescue ActiveRecord::RecordInvalid => e
      error_message = e.record.errors.full_messages.join(', ')
      redirect_to setup_index_path, alert: "Failed to create admin user: #{error_message}"
    end
  end
end
