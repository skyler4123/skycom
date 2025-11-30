import { Controller } from "@hotwired/stimulus"

export default class LinkController extends Controller {
  static targets = ["link", "openByPathname"]

  initialize() {
    setTimeout(() => {
      this.addLinkTargets()
      // this.updateLinkStyles()
      this.updateOpenByPathnameTargets()
    }, 100)
  }

  addLinkTargets() {
    this.element.querySelectorAll('a').forEach((linkElement) => {
      // linkElement.setAttribute(`data-${this.identifier}-target`, 'link')
      // append "link" to existing targets at attribute data-link-target
      linkElement.setAttribute(`data-${this.identifier}-target`, (linkElement.getAttribute(`data-${this.identifier}-target`) || '') + ' link')
    })
  }

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
