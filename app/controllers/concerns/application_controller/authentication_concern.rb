# app/controllers/concerns/application_controller/authentication_concern.rb
module ApplicationController::AuthenticationConcern
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :is_signed_in?
  end

  def current_user
    return nil unless Current.user_id
    @current_user ||= begin
      cached = Rails.sync_cache.fetch(CacheKeyService.user(Current.user_id), expires_in: CACHE_DEFAULT_EXPIRY) do
        u = User.find_by(id: Current.user_id)
        next nil unless u
        attrs = u.attributes
        u.class.defined_enums.each do |enum_name, mapping|
          value = attrs[enum_name]
          attrs[enum_name] = mapping[value] if value.is_a?(String) && mapping.key?(value)
        end
        attrs
      end
      if cached.present?
        attrs = cached.dup
        User.defined_enums.each do |enum_name, mapping|
          value = attrs[enum_name]
          attrs[enum_name] = mapping[value] if value.is_a?(String) && mapping.key?(value)
        end
        User.instantiate(attrs)
      else
        nil
      end
    end
  end

  def current_session
    return nil unless Current.session_id
    @current_session ||= Session.find_by(id: Current.session_id)
  end

  def is_signed_in?
    return false unless cookies[:is_signed_in]
    Current.session_id.present?
  end

  private

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  def set_current_session
    token = cookies.signed[:session_token]
    return unless token

    session_hash = Rails.sync_cache.fetch(CacheKeyService.session(token), expires_in: CACHE_DEFAULT_EXPIRY) do
      s = Session.find_by(id: token)
      next nil unless s
      { "id" => s.id, "user_id" => s.user_id }
    end

    if session_hash.nil?
      cleanup_invalid_session(token)
      return
    end

    Current.session_id = session_hash["id"]
    Current.user_id    = session_hash["user_id"]
  end

  def authenticate
    redirect_to main_app.root_path if !is_signed_in?
  end

  def cleanup_invalid_session(token)
    Rails.sync_cache.delete(CacheKeyService.session(token))
    cookies.delete(:session_token)
    cookies.delete(:is_signed_in)
  end
end
