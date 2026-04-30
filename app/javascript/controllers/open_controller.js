// How to use:
// add 'data-open-target="trigger" data-action="click->open#click" data-open-group-param="uniqueGroup" data-open-key-param="uniqueKey"'
// add 'data-open-target="listener" data-open-group-param="uniqueGroup" data-open-key-param="uniqueKey"'

// click action will make controller loop through listener targets
// if their'group match to trigger'group, remove open attribute, then if they match with key param, set open attribute to true
// if their'group dont match with trigger's group, do nothing

// Example code:
//  <div data-controller="open"> --> This already added at server html
//    <a data-open-target="trigger" data-action="click->open#click" data-open-group-param="`group1`" data-open-key-param="`key1`">Trigger 1</a>
//    <a data-open-target="trigger" data-action="click->open#click" data-open-group-param="`group1`" data-open-key-param="`key2`">Trigger 2</a>
//    <a data-open-target="trigger" data-action="click->open#click" data-open-group-param="`group1`" data-open-key-param="`key3`">Trigger 3</a>
//    
//    <div data-open-target="listener" data-open-group-param="`group1`" data-open-key-param="`key1`">Listener 1</div>
//    <div data-open-target="listener" data-open-group-param="`group1`" data-open-key-param="`key2`">Listener 2</div>
//    <div data-open-target="listener" data-open-group-param="`group1`" data-open-key-param="`key3`">Listener 3</div>
//  </div>

// <a
//   class="flex"
//   ${openByPathname()}
// >
import { Controller } from "@hotwired/stimulus"

export default class OpenController extends Controller {
  static targets = ["trigger", "listener", "openByPathname"]

  connect() {
    // Assuming poll is defined globally or imported elsewhere
    if (typeof poll === "function") {
      poll(() => {
        this.updateOpenByPathnameTargets()
        return this.openByPathnameTargets.every(target => target.hasAttribute("open"))
      })
    }
  }

  click(event) {
    event.preventDefault()

    const { group, key, toggle } = event.params
    
    // 1. Identify if the current target is already open
    const isAlreadyOpen = this.listenerTargets.find(
      (l) => String(l.dataset.openGroupParam) === String(group) && 
             String(l.dataset.openKeyParam) === String(key)
    )?.hasAttribute("open")

    // 2. Determine if we should be closing the item instead of opening it
    const shouldClose = toggle && isAlreadyOpen

    // Update Triggers
    if (this.hasTriggerTarget) {
      this.triggerTargets.forEach((trigger) => {
        if (String(trigger.dataset.openGroupParam) === String(group)) {
          const isMatch = String(trigger.dataset.openKeyParam) === String(key)
          
          if (isMatch && !shouldClose) {
            trigger.setAttribute("open", "")
          } else {
            trigger.removeAttribute("open")
          }
        }
      })
    }

    // Update Listeners
    if (this.hasListenerTarget) {
      this.listenerTargets.forEach((listener) => {
        if (String(listener.dataset.openGroupParam) === String(group)) {
          const isMatch = String(listener.dataset.openKeyParam) === String(key)
          
          if (isMatch && !shouldClose) {
            listener.setAttribute("open", "")
          } else {
            listener.removeAttribute("open")
          }
        }
      })
    }
  }

  updateOpenByPathnameTargets() {
    const currentPath = window.location.pathname

    this.openByPathnameTargets.forEach((linkElement) => {
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