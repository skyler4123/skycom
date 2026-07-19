// app/javascript/controllers/websocket_controller.js

import { Controller } from "@hotwired/stimulus"
import { Centrifuge } from "centrifuge"

export default class WebsocketController extends Controller {
  static values = {
    url: String,
    token: String
  }

  connect() {
    console.log("⚡ Core WebSockets Gateway mounted.")
    this.initializeGlobalInterface()
    this.initializeCentrifuge()
  }

  disconnect() {
    if (window.WEBSOCKET && window.WEBSOCKET.cable) {
      window.WEBSOCKET.cable.disconnect()
      console.log("🔌 Connection closed cleanly.")
    }
    // Wipe the object on teardown to prevent memory leaks across page transitions
    window.WEBSOCKET = null
  }

  initializeGlobalInterface() {
    // Expose the global namespace matching your backend naming strategy
    window.WEBSOCKET = {
      // 1. Manually synced Event Registry from BE (Websocket::EVENTS)
      EVENTS: {
        test: "test",
        top_up_completed: "top_up.completed",
        invoice_paid:     "invoice.paid",
        balance_updated:  "balance.updated",
        alert_triggered:  "alert.triggered"
      },

      // 2. Channel Generators mirroring your Ruby methods
      companyChannel(companyId) {
        return companyId ? `${companyId}` : null
      },

      userChannel(userId) {
        return userId ? `${userId}` : null
      },

      // 3. System references managed by the engine
      cable: null,
      activeSubscriptions: {},

      // 4. The Global Subscription Hook used by other controllers
      subscribe(channelName, eventKey, callback) {
        if (!this.cable) {
          console.warn(`⚠️ WEBSOCKET connection engine is not ready yet.`)
          return null
        }

        const expectedEvent = this.EVENTS[eventKey]
        if (!expectedEvent) {
          console.error(`🛑 Unregistered event key rejected: [${eventKey}]`)
          return null
        }

        // Multiplexing check: reuse subscription if it already exists for this channel
        let sub = this.activeSubscriptions[channelName]
        if (!sub) {
          sub = this.cable.newSubscription(channelName)
          sub.subscribe()
          this.activeSubscriptions[channelName] = sub
          console.log(`🔗 Pipeline subscribed to channel stream: [${channelName}]`)
        }

        // Listen for incoming publications and execute the matching callback type
        sub.on('publication', (ctx) => {
          if (ctx.data?.event === expectedEvent) {
            callback(ctx.data.id, ctx.data.payload)
          }
        })

        return sub
      }
    }
  }

  initializeCentrifuge() {
    // Initialize root engine
    const centrifuge = new Centrifuge(this.urlValue, {
      token: this.tokenValue
    })

    // Mount references onto the global gateway
    window.WEBSOCKET.cable = centrifuge

    // Open the connection pipe
    centrifuge.connect()
  }
}


// How to use

// // app/javascript/controllers/billing_page_controller.js
// import { Controller } from "@hotwired/stimulus"

// export default class extends Controller {
//   static values = { companyId: String }

//   connect() {
//     // 1. Generate the channel name matching the backend format
//     const channel = window.WEBSOCKET.companyChannel(this.companyIdValue)

//     // 2. Safely attach a dynamic listener using the synced event registry key
//     window.WEBSOCKET.subscribe(channel, "top_up_completed", (resourceId, payload) => {
//       this.handleInvoiceSuccess(resourceId, payload)
//     })
//   }

//   handleInvoiceSuccess(id, payload) {
//     console.log(`🟢 Top Up completed for entity ID: ${id}`)
//     // Update your UI state or run local actions here...
//   }
// }