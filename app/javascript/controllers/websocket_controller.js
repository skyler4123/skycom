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

    console.log(`⚡ SharedWorker WebSockets Gateway mounted (Centrifugo: ${this.centrifugePath}, URL: ${this.urlValue})`)
    this.logTokenClaims()

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

  // Console diagnostics — decode the connection token (no signature check) so the
  // console shows which channels Centrifugo will actually accept from this browser.
  logTokenClaims() {
    try {
      const payload = this.tokenValue.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")
      const claims = JSON.parse(atob(payload))
      console.log("🔑 [WS] token claims", { sub: claims.sub, channels: claims.channels || [] })
    } catch (error) {
      console.warn("⚠️ [WS] could not decode connection token claims")
    }
  }

  // Forwarded by the SharedWorker — this is Centrifugo's actual answer, not just
  // the page's subscribe intent.
  logSubscriptionState({ channel, state, reason, reused }) {
    const message = `📡 [WS] subscription ${state}${reused ? " (shared worker)" : ""} → "${channel}"`
    if (state === "error") {
      console.error(`${message} — ${reason || "unknown error"}`)
    } else {
      console.log(message)
    }
  }

  logConnectionState({ state, reason, url }) {
    const target = url ? ` → ${url}` : ""
    const message = `🔌 [WS] connection ${state}${target}${reason ? ` — ${reason}` : ""}`
    if (state === "error") {
      console.error(message)
    } else {
      console.log(message)
    }
  }

  initializeSharedWorker() {
    // Construct worker script using native ES module import
    const workerScript = `
      import { Centrifuge } from "${window.location.origin}${this.centrifugePath}";

      const ports = new Set();
      let centrifuge = null;
      let activeSubscriptions = {};
      let connectionIdentity = null;
      let connectionState = "disconnected";
      let connectionUrl = null;

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

      // The SharedWorker outlives page loads, but its connection token belongs
      // to the user/company of the page that created it. Reusing that token
      // after the identity changes makes Centrifugo reject the new company's
      // channel subscriptions. Compare the token claims, not the raw token, so
      // same-identity page loads keep the existing connection.
      function identityFor(url, token) {
        try {
          const payload = JSON.parse(atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
          return JSON.stringify({ url, sub: payload.sub, channels: payload.channels || [] });
        } catch (error) {
          return url + "|" + token;
        }
      }

      function initCentrifugo(url, token) {
        const identity = identityFor(url, token);
        connectionUrl = url;

        if (centrifuge && identity === connectionIdentity) {
          // Another tab reused this worker's connection: tell the new page where
          // the connection currently stands so its console is not silent.
          broadcast({
            action: "CONNECTION_STATE",
            state: connectionState,
            url: connectionUrl,
            reason: "shared worker connection reused"
          });
          return;
        }

        if (centrifuge) {
          Object.values(activeSubscriptions).forEach((sub) => {
            try { sub.unsubscribe(); } catch (error) {}
          });
          try { centrifuge.disconnect(); } catch (error) {}
        }

        activeSubscriptions = {};
        connectionIdentity = identity;
        centrifuge = new Centrifuge(url, { token });

        centrifuge.on("connecting", () => {
          connectionState = "connecting";
          broadcast({ action: "CONNECTION_STATE", state: "connecting", url: connectionUrl });
        });

        centrifuge.on("connected", () => {
          connectionState = "connected";
          broadcast({ action: "CONNECTION_STATE", state: "connected", url: connectionUrl });
        });

        centrifuge.on("disconnected", (ctx) => {
          connectionState = "disconnected";
          broadcast({ action: "CONNECTION_STATE", state: "disconnected", url: connectionUrl, reason: ctx && ctx.reason });
        });

        centrifuge.on("error", (ctx) => {
          broadcast({ action: "CONNECTION_STATE", state: "error", url: connectionUrl, reason: ctx && ctx.error && ctx.error.message });
        });

        centrifuge.connect();
      }

      function subscribeChannel(channel) {
        if (!centrifuge) return;

        if (activeSubscriptions[channel]) {
          // The worker already holds this subscription: report its live state so
          // a newly opened tab still sees the channel confirmation.
          broadcast({
            action: "SUBSCRIPTION_STATE",
            channel: channel,
            state: activeSubscriptions[channel].state || "unknown",
            reused: true
          });
          return;
        }

        const sub = centrifuge.newSubscription(channel);
        sub.on("publication", (ctx) => {
          broadcast({
            action: "PUBLICATION",
            channel: channel,
            data: ctx.data
          });
        });

        sub.on("subscribed", () => {
          broadcast({ action: "SUBSCRIPTION_STATE", channel: channel, state: "subscribed" });
        });

        sub.on("unsubscribed", (ctx) => {
          broadcast({ action: "SUBSCRIPTION_STATE", channel: channel, state: "unsubscribed", reason: ctx && ctx.reason });
        });

        sub.on("error", (ctx) => {
          broadcast({ action: "SUBSCRIPTION_STATE", channel: channel, state: "error", reason: ctx && ctx.error && ctx.error.message });
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

      if (action === "PUBLICATION") {
        if (window.WEBSOCKET) {
          window.WEBSOCKET.handleIncomingPublication(channel, data)
        }
      } else if (action === "SUBSCRIPTION_STATE") {
        this.logSubscriptionState(event.data)
      } else if (action === "CONNECTION_STATE") {
        this.logConnectionState(event.data)
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
      // 1. Event Registry (key === value — the wire string matches the symbol key)
      EVENTS: {
        test: "test",
        top_up_completed: "top_up_completed",
        pos_payment_completed: "pos_payment_completed",
        notification_created: "notification_created",
        company_ticket_created: "company_ticket_created",
        company_ticket_commented: "company_ticket_commented",
        company_ticket_status_changed: "company_ticket_status_changed",
        ticket_created: "ticket_created",
        ticket_commented: "ticket_commented",
        ticket_workflow_step_changed: "ticket_workflow_step_changed",
        ticket_assigned: "ticket_assigned",
        import_progress: "import_progress",
        import_finished: "import_finished"
      },

      // 2. Channel Generator — format "<model>_<id>" e.g. "company_<uuid>", "user_<uuid>".
      channelName(modelName, id) {
        return modelName && id ? `${String(modelName).toLowerCase()}_${id}` : null
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

          console.log(`📡 [WS] subscribe → "${channelName}" (event: "${expectedEvent}")`)
        } else {
          console.log(`📡 [WS] extra listener → "${channelName}" (event: "${expectedEvent}", already subscribed)`)
        }

        const listener = { eventKey: expectedEvent, callback }
        this.listeners[channelName].push(listener)

        return {
          unsubscribe: () => {
            this.listeners[channelName] = this.listeners[channelName].filter(l => l !== listener)
            console.log(`📡 [WS] listener removed → "${channelName}" (event: "${expectedEvent}")`)
          }
        }
      },

      // Internal publication dispatcher
      handleIncomingPublication(channel, data) {
        // Every publication that reaches this tab, before any event filtering.
        console.log(`📨 [WS] message ← "${channel}"`, data)

        const channelListeners = this.listeners[channel]
        if (!channelListeners) {
          console.warn(`⚠️ [WS] no local listener for "${channel}" in this tab — message dropped`)
          return
        }

        if (!data?.event) {
          console.warn(`⚠️ [WS] message on "${channel}" has no "event" field — dropped`, data)
          return
        }

        const registeredEvents = [...new Set(channelListeners.map(listener => listener.eventKey))]
        if (!registeredEvents.includes(data.event)) {
          console.warn(`⚠️ [WS] "${channel}" has no listener for event "${data.event}" (listening: ${registeredEvents.join(", ")})`)
        }

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

// window.WEBSOCKET.subscribe(window.WEBSOCKET.channelName("company", currentCompany().id), "test", (data) => {
//   console.log(data)
// })