class Mobile::Companies::NotificationsController < Mobile::Companies::BaseController
  def index
    @notifications = Notification.subscribed_for(@employee, @company).order(created_at: :desc)
  end
end
