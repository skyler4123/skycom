// How to add "open" attribute to links that match the current pathname
// data-link-target="openByPathname"

import { Controller } from "@hotwired/stimulus"
import * as Helpers from "controllers/helpers"

export default class LinkController extends Controller {
  static targets = ["link", "openByPathname"]

  initialize() {
    Helpers.poll(() => {
      this.addLinkTargets()
      this.updateOpenByPathnameTargets()
    })
  }

  addLinkTargets() {
    this.element.querySelectorAll('a').forEach((linkElement) => {
      Helpers.addAttribute(linkElement, `data-${this.identifier}-target`, 'link')
    })
  }

  // Make sure openByPathname targets were added 
  updateOpenByPathnameTargets() {
    const currentPath = window.location.pathname

    this.openByPathnameTargets.forEach((linkElement) => {
      // If the link doesn't have an href, skip to the next iteration.
      if (!linkElement.href) {
        // console the text inside "Link element has no href:" and the linkElement
        console.log("Link element has no href:", linkElement.innerText)
        return; // Acts like 'continue' in a forEach loop
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
