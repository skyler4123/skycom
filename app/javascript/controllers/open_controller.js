// <%# If user clicks Trigger 2, it saves "sidebar" -> "settings" to localStorage %>
// <a <%= addOpenTrigger(group: "sidebar", key: "settings", cache: true) %>>Settings</a>
// <a <%= addOpenTrigger(group: "sidebar", key: "profile", cache: true) %>>Profile</a>

// <%# On page reload, the controller checks "sidebar" cache and re-opens the last one %>
// <div <%= addOpenListener(group: "sidebar", key: "settings", cache: true) %>>Settings Content</div>
// <div <%= addOpenListener(group: "sidebar", key: "profile", cache: true) %>>Profile Content</div>

import { Controller } from "@hotwired/stimulus"

export default class OpenController extends Controller {
  static targets = ["trigger", "listener", "openByPathname"]

  connect() {
    poll(() => {
      this.updateOpenByPathnameTargets()
    })

    poll(() => {
      if (this.hasListenerTarget) {
        this.checkCache()
        return true
      }
    })
  }

  checkCache() {
    // Collect all unique groups that have at least one listener requesting cache
    const groupsToCache = [...new Set(
      this.listenerTargets
        .filter(l => l.dataset.openCacheParam === "true")
        .map(l => l.dataset.openGroupParam)
    )]
    groupsToCache.forEach(group => {
      const cachedKey = localStorage.getItem(`open-cache-${group}`)
      if (cachedKey) {
        this.applyState(group, cachedKey, false)
      }
    })
  }

  click(event) {
    event.preventDefault()
    const { group, key, toggle, cache } = event.params
    
    const isAlreadyOpen = this.listenerTargets.find(
      (l) => String(l.dataset.openGroupParam) === String(group) && 
             String(l.dataset.openKeyParam) === String(key)
    )?.hasAttribute("open")

    const shouldClose = toggle && isAlreadyOpen

    // Update Cache if enabled
    if (cache) {
      if (shouldClose) {
        localStorage.removeItem(`open-cache-${group}`)
      } else {
        localStorage.setItem(`open-cache-${group}`, key)
      }
    }

    this.applyState(group, key, shouldClose)
  }

  // Refactored UI update logic into a single method
  applyState(group, key, shouldClose) {
    const update = (targets) => {
      targets.forEach((el) => {
        if (String(el.dataset.openGroupParam) === String(group)) {
          const isMatch = String(el.dataset.openKeyParam) === String(key)
          isMatch && !shouldClose ? el.setAttribute("open", "") : el.removeAttribute("open")
        }
      })
    }

    if (this.hasTriggerTarget) update(this.triggerTargets)
    if (this.hasListenerTarget) update(this.listenerTargets)
  }

  updateOpenByPathnameTargets() {
    const currentPath = window.location.pathname

    this.openByPathnameTargets.forEach((linkElement) => {
      if (linkElement.hasAttribute("open")) return; 
      if (!linkElement.href) {
        console.log("Link element has no href:", linkElement.innerText)
        return
      }

      const linkPath = new URL(linkElement.href).pathname
      if (linkPath === currentPath) {
        linkElement.setAttribute("open", "")
      } else {
        linkElement.removeAttribute("open")
      }
    })
  }
}