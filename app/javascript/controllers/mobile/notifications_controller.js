import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { companyId: String }

  connect() {
    const ws = window.WEBSOCKET
    if (!ws?.channelName || !ws?.subscribe) return

    const channel = ws.channelName("company", this.companyIdValue)
    if (!channel) return

    ws.subscribe(channel, "notification_created", () => {
      window.location.reload()
    })
  }
}