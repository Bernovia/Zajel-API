class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  rescue_from Pagy::OverflowError, with: :render_pagination_error
  include Pagy::Backend

  around_action :switch_locale

  before_action :configure_permitted_parameters, if: :devise_controller?, except: :callback
  before_action :get_request
  before_action :check_user_confirmation_status, unless: :devise_controller?
  after_action { pagy_headers_merge(@pagy) if @pagy }

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name,
                                                       :last_name,
                                                       :birth_date,
                                                       :phone_number,
                                                       :fcm_token])
  end

  def render_pagination_error
    render json: {errors: []}, status: 200
  end

  def switch_locale(&action)
    current_user.update_columns(locale: request.headers['locale']) if current_user && current_user.locale != request.headers['locale']
    locale = request.headers['locale'] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def check_user_confirmation_status
    # if current_user && current_user.confirmed_at.nil?
    #   render json: { error: { message: 'user not confirmed' } }, status: :forbidden
    # end
  end

  def get_request
    unless request.original_fullpath.include?('api/admin/')
      Request.create(user_email: current_user&.email,
                     remote_ip: request.remote_ip,
                     controller_class: request.controller_class,
                     original_path: request.original_fullpath,
                     method: request.method)
    end
  end
end
