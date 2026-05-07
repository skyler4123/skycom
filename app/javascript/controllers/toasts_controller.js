// app/javascript/controllers/toasts_controller.js
import { Controller } from "@hotwired/stimulus"

/**
 * ToastsController handles the delivery of persistent notifications across page reloads.
 * It monitors localStorage for queued messages and displays them via Toastify on connection.
 * * @example
 * <body data-controller="toasts"> ... </body>
 */

export default class extends Controller {
  connect() {
    this.processPendingToasts();
  }

  processPendingToasts() {
    const data = localStorage.getItem(Helpers.PENDING_TOASTS_KEY);
    if (!data) return;

    try {
      const pendingToasts = JSON.parse(data);

      if (Array.isArray(pendingToasts) && pendingToasts.length > 0) {
        // 1. Fire each toast
        pendingToasts.forEach((t) => {
          // Check if it's a simple string or a full object
          const options = typeof t === "string" ? { message: t } : t;
          toast(options);
        });

        // 2. Clear the storage so they don't fire again on next refresh
        this.clearStorage();
      }
    } catch (e) {
      console.error("Failed to process pending toasts", e);
      this.clearStorage();
    }
  }

  clearStorage() {
    localStorage.removeItem(Helpers.PENDING_TOASTS_KEY);
  }
}