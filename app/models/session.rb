# app/models/session.rb
class Session < ApplicationRecord
  include Cache::RecordsConcern

  belongs_to :user

  # Callbacks
  before_create :set_request_details

  private

  def set_request_details
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end
end
