# frozen_string_literal: true

# Session — Atomic purpose: one signed-in browser session for a User.
#
# Why it exists: sign-in must be revocable per device; deleting the Session row
# (or letting its cache entry expire) invalidates that browser without touching
# the user's password.
# How it works: before_create copies Current.user_agent/ip_address, and
# after_commit writes or removes a short-lived `sessions_<id>` entry in
# Rails.sync_cache (SESSION_CACHE_EXPIRY). The authentication concern reads that
# cache before falling back to the database.
# Main associations: belongs_to :user (required).
class Session < ApplicationRecord
  SESSION_CACHE_EXPIRY = 1.hour

  belongs_to :user

  # Callbacks
  before_create :set_request_details

  after_commit :refresh_cache, on: [ :create, :update ]
  after_commit :remove_cache, on: :destroy

  private

  def refresh_cache
    Rails.sync_cache.write(
      "sessions_#{id}",
      { "id" => id, "user_id" => user_id },
      expires_in: SESSION_CACHE_EXPIRY
    )
  end

  def remove_cache
    Rails.sync_cache.delete("sessions_#{id}")
  end

  def set_request_details
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end
end
