# frozen_string_literal: true

class Mobile::Companies::NotificationsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Notification)
  end
end
