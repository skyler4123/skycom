// app/javascript/controllers/client_cache_controller.js
import { Controller } from "@hotwired/stimulus"

export default class ClientCacheController extends Controller {
  static values = { version: String }

  connect() {
    this.sync()
  }

  clearClientCache() {
    Helpers.removeLocalStorage("client_cache_data")
    Helpers.removeLocalStorage("client_cache_version")
  }

  async sync() {
    const serverVersion = Cookie('client_cache_version')
    const localVersion = localStorage.getItem('client_cache_version')

    if (serverVersion && serverVersion !== localVersion) {
      await this.refreshCache(serverVersion)
    }
  }

  async refreshCache(newVersion) {
    try {
      // One API call to get everything: companies, branches, user profile, etc.
      const data = await fetchJson('/client_cache')
      
      // Store the payload
      localStorage.setItem('client_cache_data', JSON.stringify(data))
      localStorage.setItem('client_cache_version', newVersion)
      
      // Dispatch a global event so other controllers know data changed
      window.dispatchEvent(new CustomEvent("client-cache:updated", { detail: data }))
      
      console.log("Client Cache updated to:", newVersion)
    } catch (error) {
      console.error("Client Cache sync failed:", error)
    }
  }
}