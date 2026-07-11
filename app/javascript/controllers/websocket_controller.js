// app/javascript/controllers/websocket_controller.js

import { Controller } from "@hotwired/stimulus"
import { Centrifuge } from "centrifuge"

export default class WebsocketController extends Controller {
  // Read configuration values passed safely from the HTML view template
  static values = {
    url: String,
    token: String,
    channel: String
  }

  connect() {
    console.log("WebSocket Test Stimulus Controller Connected to DOM.")
    this.initializeCentrifuge()
  }

  disconnect() {
    // Gracefully clean up the connection if the user leaves the page
    if (this.centrifuge) {
      this.centrifuge.disconnect()
      console.log("Centrifugo disconnected cleanly.")
    }
  }

  initializeCentrifuge() {
    // 1. Initialize the Centrifugo client using the signed token
    this.centrifuge = new Centrifuge(this.urlValue, {
      token: this.tokenValue
    })

    // 2. Create a subscription to your dynamic channel target
    this.subscription = this.centrifuge.newSubscription(this.channelValue)

    // 3. Bind the live event hook to listen for data updates
    this.subscription.on('publication', (ctx) => {
      console.log("🚀 Live Message Arrived From Rails Backend:")
      console.dir(ctx.data) // Prints the interactive JSON object directly to the console
    })

    // 4. Activate the stream
    this.subscription.subscribe()
    this.centrifuge.connect()

    console.log(`Centrifugo listening closely to channel: ${this.channelValue}`)
  }
}
