// app/javascript/controllers/websocket_controller.js
import { Controller } from "@hotwired/stimulus"

export default class WebsocketController extends Controller {
  static values = {
    url: String,
    token: String
  }

  connect() {
    if (!this.hasUrlValue) {
      console.log("⚡ WebSocket skipped (not authenticated)")
      return
    }

    if (!window.SharedWorker) {
      console.warn("⚠️ SharedWorker is not supported in this browser.")
      return
    }

    // 1. Resolve local fingerprinted path of Centrifugo from importmap in <head>
    this.centrifugePath = this.getImportMapPath("centrifuge")
    if (!this.centrifugePath) {
      console.error("🛑 Could not find 'centrifuge' pinned in importmap!")
      return
    }

    console.log(`⚡ SharedWorker WebSockets Gateway mounted (Centrifugo: ${this.centrifugePath})`)
    
    // 2. Initialize SharedWorker & global window interface
    this.initializeSharedWorker()
    this.initializeGlobalInterface()
  }

  disconnect() {
    if (this.workerPort) {
      this.workerPort.close()
    }
    window.WEBSOCKET = null
  }

  getImportMapPath(moduleName) {
    const importMapScript = document.querySelector('script[type="importmap"]')
    if (!importMapScript) return null

    try {
      const importMap = JSON.parse(importMapScript.textContent)
      return importMap.imports[moduleName] || null
    } catch (e) {
      return null
    }
  }

  initializeSharedWorker() {
    // Construct worker script using native ES module import
    const workerScript = `
      import { Centrifuge } from "${window.location.origin}${this.centrifugePath}";

      const ports = new Set();
      let centrifuge = null;
      let activeSubscriptions = {};

      self.onconnect = (e) => {
        const port = e.ports[0];
        ports.add(port);

        port.onmessage = (event) => {
          const { action, payload } = event.data;

          switch (action) {
            case "INIT_CENTRIFUGO":
              initCentrifugo(payload.url, payload.token);
              break;
            case "SUBSCRIBE":
              subscribeChannel(payload.channel);
              break;
          }
        };

        port.start();
      };

      function initCentrifugo(url, token) {
        if (centrifuge) return;

        centrifuge = new Centrifuge(url, { token });
        centrifuge.connect();
      }

      function subscribeChannel(channel) {
        if (!centrifuge || activeSubscriptions[channel]) return;

        const sub = centrifuge.newSubscription(channel);
        sub.on("publication", (ctx) => {
          broadcast({
            action: "PUBLICATION",
            channel: channel,
            data: ctx.data
          });
        });

        sub.subscribe();
        activeSubscriptions[channel] = sub;
      }

      function broadcast(message) {
        ports.forEach((port) => {
          try {
            port.postMessage(message);
          } catch (err) {
            ports.delete(port);
          }
        });
      }
    `

    // Encode into a Data URL to prevent Blob URL CORS/opaque origin blocks on reload
    const dataUrl = `data:text/javascript;charset=utf-8,${encodeURIComponent(workerScript)}`

    // Instantiate as an ES module worker
    this.worker = new SharedWorker(dataUrl, { type: "module" })
    this.workerPort = this.worker.port

    // Listen for events fan-outed from the SharedWorker
    this.workerPort.onmessage = (event) => {
      const { action, channel, data } = event.data
      if (action === "PUBLICATION" && window.WEBSOCKET) {
        window.WEBSOCKET.handleIncomingPublication(channel, data)
      }
    }

    this.workerPort.start()

    // Initialize Centrifugo connection inside worker thread
    this.workerPort.postMessage({
      action: "INIT_CENTRIFUGO",
      payload: { url: this.urlValue, token: this.tokenValue }
    })
  }

  initializeGlobalInterface() {
    const self = this

    window.WEBSOCKET = {
      // 1. Event Registry
      EVENTS: {
        test: "test",
        top_up_completed: "top_up.completed",
        invoice_paid:     "invoice.paid",
        balance_updated:  "balance.updated",
        alert_triggered:  "alert.triggered"
      },

      // 2. Channel Generators
      companyChannel(companyId) {
        return companyId ? `${companyId}` : null
      },

      userChannel(userId) {
        return userId ? `${userId}` : null
      },

      // 3. Local tab listener registry
      listeners: {},

      // 4. Global Subscription Hook
      subscribe(channelName, eventKey, callback) {
        const expectedEvent = this.EVENTS[eventKey]
        if (!expectedEvent) {
          console.error(`🛑 Unregistered event key rejected: [${eventKey}]`)
          return null
        }

        if (!this.listeners[channelName]) {
          this.listeners[channelName] = []

          // Tell SharedWorker to subscribe on Centrifugo if not already active
          self.workerPort.postMessage({
            action: "SUBSCRIBE",
            payload: { channel: channelName }
          })
        }

        const listener = { eventKey: expectedEvent, callback }
        this.listeners[channelName].push(listener)

        return {
          unsubscribe: () => {
            this.listeners[channelName] = this.listeners[channelName].filter(l => l !== listener)
          }
        }
      },

      // Internal publication dispatcher
      handleIncomingPublication(channel, data) {
        const channelListeners = this.listeners[channel]
        if (!channelListeners || !data?.event) return

        channelListeners.forEach(({ eventKey, callback }) => {
          if (data.event === eventKey) {
            callback(data)
          }
        })
      }
    }
  }
}

// How to use:

// window.WEBSOCKET.subscribe(window.WEBSOCKET.companyChannel(currentCompany().id), "test", (data) => {
//   console.log(data)
// })