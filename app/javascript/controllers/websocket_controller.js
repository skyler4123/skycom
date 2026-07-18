// app/javascript/controllers/websocket_controller.js

import { Controller } from "@hotwired/stimulus"
import { Centrifuge } from "centrifuge"

export default class WebsocketController extends Controller {
  static values = {
    url: String,
    token: String,
    channel: Array // Changed from String to Array
  }

  connect() {
    console.log("WebSocket Stimulus Controller Connected to DOM.")
    this.subscriptions = {} // Track active subscription objects here
    this.initializeCentrifuge()
  }

  disconnect() {
    if (this.centrifuge) {
      this.centrifuge.disconnect()
      console.log("Centrifugo connection closed cleanly.")
    }
  }

  initializeCentrifuge() {
    // 1. Initialize the root client connection
    this.centrifuge = new Centrifuge(this.urlValue, {
      token: this.tokenValue
    })

    // 2. Iterate through each channel passed in the Array value
    this.channelValue.forEach((channelName) => {
      console.log(`Setting up subscription for channel: ${channelName}`)
      
      // Create subscription instance for this specific channel string
      const sub = this.centrifuge.newSubscription(channelName)

      // Bind data reception logic
      sub.on('publication', (ctx) => {
        this.handleIncomingMessage(channelName, ctx.data)
      })

      // Activate sub stream and store reference
      sub.subscribe()
      this.subscriptions[channelName] = sub
    })

    // 3. Connect to the Centrifugo cluster engine
    this.centrifuge.connect()
  }

  // Centrally handle data events, routing logic based on channel origins
  handleIncomingMessage(channel, data) {
    console.log(`🚀 Live Message Arrived from [${channel}]:`)
    console.dir(data)

    // Example routing: You can dispatch customized events up your DOM tree if needed
    // this.element.dispatchEvent(new CustomEvent(`ws:${channel}`, { detail: data }))
  }
}
