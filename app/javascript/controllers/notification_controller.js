
import ApplicationController from "controllers/application_controller";

export default class NotificationController extends ApplicationController {
  static targets = ["notificationList", "notificationBell"];
  static values = {
    notifications: { type: Array, default: [] },
    unreadCount: { type: Number, default: 0 },
  }

  connect() {
    this.updateNotificationUI();
  }

  notificationsValueChanged(value, previousValue) {
    this.updateNotificationUI();
  }

  unreadCountValueChanged(value, previousValue) {
    this.updateNotificationUI();
  }

  updateNotificationUI() {
    // Update the notification list UI
    this.notificationListTarget.innerHTML = this.notificationsValue.map(notification => `
      <div class="notification-item ${notification.read ? '' : 'unread'}">
        <p>${notification.message}</p>
        <span class="timestamp">${new Date(notification.timestamp).toLocaleString()}</span>
      </div>
    `).join('');

    // Update the notification bell UI
    if (this.unreadCountValue > 0) {
      this.notificationBellTarget.classList.add('has-unread');
      this.notificationBellTarget.setAttribute('data-unread-count', this.unreadCountValue);
    } else {
      this.notificationBellTarget.classList.remove('has-unread');
      this.notificationBellTarget.removeAttribute('data-unread-count');
    }
  }
}
