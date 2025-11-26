import { Controller } from "@hotwired/stimulus"

export default class LinkController extends Controller {
  static targets = ["link"]

  initialize() {
    this.element.querySelectorAll('a').forEach((linkElement) => {
      linkElement.setAttribute(`data-${this.identifier}-target`, 'link')
    })
  }

  selectedClasses() {
    return "text-blue-600 bg-blue-100"
  }

  unselectedClasses() {
    return "text-gray-800 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-800"
  }

  connect() {
    this.updateLinkStyles()
  }

  updateLinkStyles() {
    const currentPath = window.location.pathname

    this.linkTargets.forEach((linkElement) => {
      const linkPath = new URL(linkElement.href).pathname

      if (linkPath === currentPath) {
        linkElement.className = this.selectedClasses()
      } else {
        linkElement.className = this.unselectedClasses()
      }
    })
  }
}
