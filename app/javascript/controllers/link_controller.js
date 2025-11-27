import { Controller } from "@hotwired/stimulus"

export default class LinkController extends Controller {
  static targets = ["link", "openByPathname"]

  initialize() {
    setTimeout(() => {
      this.addLinkTargets()
      // this.updateLinkStyles()
      this.updateOpenByPathnameTargets()
    }, 1000)
  }

  addLinkTargets() {
    this.element.querySelectorAll('a').forEach((linkElement) => {
      // linkElement.setAttribute(`data-${this.identifier}-target`, 'link')
      // append "link" to existing targets at attribute data-link-target
      linkElement.setAttribute(`data-${this.identifier}-target`, (linkElement.getAttribute(`data-${this.identifier}-target`) || '') + ' link')
    })
  }


  // updateLinkStyles() {
  //   const currentPath = window.location.pathname

  //   this.linkTargets.forEach((linkElement) => {
  //     const linkPath = new URL(linkElement.href).pathname

  //     if (linkPath === currentPath) {
  //       // linkElement.className = this.selectedClasses()
  //     } else {
  //       // linkElement.className = this.unselectedClasses()
  //     }
  //   })
  // }
  updateOpenByPathnameTargets() {
    const currentPath = window.location.pathname

    this.openByPathnameTargets.forEach((linkElement) => {
      const linkPath = new URL(linkElement.href).pathname
      console.log('linkPath', linkPath)
      console.log('currentPath', currentPath)
      if (linkPath === currentPath) {
        linkElement.setAttribute("open", "")
      }
    })
  }
}
