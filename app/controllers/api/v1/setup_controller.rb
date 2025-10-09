class Api::V1::SetupController < ApplicationController
  # Отключаем CSRF защиту для API
  skip_before_action :verify_authenticity_token, only: [:create_admin]
  
  # Создание админа через API (только если нет ни одного админа)
  def create_admin
    # Проверяем, есть ли уже админы
    if User.where(role: :admin).exists?
      render json: { 
        error: 'Admin user already exists',
        message: 'An admin user has already been created'
      }, status: :conflict
      return
    end

    # Параметры из запроса или значения по умолчанию
    email = params[:email] || 'admin@bms.com'
    password = params[:password] || 'password123'
    first_name = params[:first_name] || 'Admin'
    last_name = params[:last_name] || 'User'

    begin
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        first_name: first_name,
        last_name: last_name,
        role: :admin
      )

      render json: {
        success: true,
        message: 'Admin user created successfully',
        user: {
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.display_role,
          full_name: user.full_name
        }
      }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: {
        error: 'Failed to create admin user',
        message: e.message,
        details: e.record.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # Проверка статуса админов
  def admin_status
    admin_count = User.where(role: :admin).count
    has_admin = admin_count > 0
    
    render json: {
      has_admin: has_admin,
      admin_count: admin_count,
      message: has_admin ? 'Admin users exist' : 'No admin users found'
    }
  end
end
