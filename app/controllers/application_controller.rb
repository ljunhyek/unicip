class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Health check endpoint for Render
  def health
    render json: { status: 'OK', timestamp: Time.current }
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :name, :user_type, :manager, :contact, :inventor, 
      :customer_number, :terms_agreed, :privacy_agreed, :email_agreed
    ])
    
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :name, :user_type, :manager, :contact, :inventor, 
      :customer_number, :email_agreed
    ])
  end

  def current_admin_user
    current_admin_user_session&.admin_user
  end

  def authenticate_admin_user!
    redirect_to new_admin_admin_user_session_path unless current_admin_user
  end

  def ensure_admin_access
    render_access_denied unless current_admin_user&.can_manage_users?
  end

  def render_access_denied
    render json: { error: 'Access denied' }, status: :forbidden
  end

  def set_current_user
    @current_user = current_user
  end

  def handle_api_errors
    yield
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'Record not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "API Error: #{e.message}"
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end
end