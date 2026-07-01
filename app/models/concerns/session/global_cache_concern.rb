module Session::GlobalCacheConcern
  extend ActiveSupport::Concern

  included do
    after_create_commit :write_session_to_global_cache
    after_commit :remove_session_from_global_cache, on: :destroy
  end

  private

  def write_session_to_global_cache
    Rails.global_session_cache.write(id, true, expires_in: COOKIE_EXPIRY)
  end

  def remove_session_from_global_cache
    Rails.global_session_cache.delete(id)
  end
end
