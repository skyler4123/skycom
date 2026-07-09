// app/javascript/controllers/client_cache_controller.js
import { Controller } from "@hotwired/stimulus"

const SYNC_COUNT_KEY = "client_cache_sync_count"
const MAX_AUTO_SYNC = 1

export default class ClientCacheController extends Controller {
  async connect() {
    if (!isSignedIn()) {
      console.log("Client cache: user not signed in, skipping sync")
      return
    }
    await this.sync()
  }

  async sync() {
    console.log("Client cache: checking sync conditions...")

    const serverVersion = Cookie("client_cache_version")
    const localVersion = localStorage.getItem("client_cache_version")
    const hasLocalCache = !!localStorage.getItem("client_cache_data")
    const syncCount = parseInt(localStorage.getItem(SYNC_COUNT_KEY) || "0", 10)

    const needsSync = !hasLocalCache || !serverVersion || serverVersion !== localVersion

    if (!needsSync) {
      console.log(`Client cache: versions match (server: ${serverVersion}, local: ${localVersion}), resetting counter`)
      localStorage.setItem(SYNC_COUNT_KEY, "0")
      console.log("Client cache: it synced, dont need to re-sync")
      return
    }

    if (syncCount >= MAX_AUTO_SYNC) {
      console.log(`Client cache: sync skipped, reached max (${MAX_AUTO_SYNC})`)
      return
    }

    console.log(`Client cache: sync needed (no cache=${!hasLocalCache}, no server version=${!serverVersion}, mismatch=${serverVersion !== localVersion}). Proceeding...`)

    await this.refreshCache(serverVersion || "initial")
  }

  async refreshCache(newVersion) {
    console.log("Client cache: fetching data from /client_cache...")

    try {
      const data = await fetchJson("/client_cache")
      console.log("Client cache: data received, storing to localStorage")

      localStorage.setItem("client_cache_data", JSON.stringify(data))
      localStorage.setItem("client_cache_version", newVersion)

      const newCount = parseInt(localStorage.getItem(SYNC_COUNT_KEY) || "0", 10) + 1
      localStorage.setItem(SYNC_COUNT_KEY, String(newCount))

      console.log(`Client cache: synced (run #${newCount}) to version ${newVersion}.`)
    } catch (error) {
      console.error("Client cache: fetch failed —", error)
    }
  }
}
