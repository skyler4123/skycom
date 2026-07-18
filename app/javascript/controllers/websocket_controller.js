import { Controller } from "@hotwired/stimulus"
import { Centrifuge } from "centrifuge"

export default class WebsocketController extends Controller {
  static values = {
    url: String,
    token: String,
    channel: Array
  }

  connect() {
    this.subscriptions = {}
    this.initializeCentrifuge()
    document.addEventListener("ws:subscribe", this)
  }

  disconnect() {
    document.removeEventListener("ws:subscribe", this)
    if (this.centrifuge) {
      this.centrifuge.disconnect()
    }
  }

  handleEvent(event) {
    if (event.type === "ws:subscribe") {
      const { channel, token } = event.detail
      if (!channel) return

      if (this.subscriptions[channel]) return

      const sub = this.centrifuge.newSubscription(channel)

      sub.on("publication", (ctx) => {
        document.dispatchEvent(
          new CustomEvent(`ws:${channel}`, { detail: ctx.data })
        )
      })

      sub.subscribe()
      this.subscriptions[channel] = sub
    }
  }

  initializeCentrifuge() {
    this.centrifuge = new Centrifuge(this.urlValue, {
      token: this.tokenValue
    })

    this.channelValue.forEach((channelName) => {
      const sub = this.centrifuge.newSubscription(channelName)

      sub.on("publication", (ctx) => {
        document.dispatchEvent(
          new CustomEvent(`ws:${channelName}`, { detail: ctx.data })
        )
      })

      sub.subscribe()
      this.subscriptions[channelName] = sub
    })

    this.centrifuge.connect()
  }
}
