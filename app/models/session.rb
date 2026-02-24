# app/models/session.rb
class Session < ApplicationRecord
  belongs_to :user

  # Callbacks
  before_create :set_request_details

  # AUTO-INVALIDATION
  # We use after_commit to ensure the DB transaction is complete before clearing cache.
  # This covers: update, destroy, and destroy_all
  after_commit :invalidate_auth_cache, on: [ :update, :destroy ]

  private

  def set_request_details
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end

  def invalidate_auth_cache
    # self.class.cache_key_for(id) calls the method in ApplicationRecord
    # Generates key like: "session/a1b2c3d4"
    Rails.cache.delete(self.class.cache_key_for(id))
  end
end
