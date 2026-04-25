import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    html: String,
    position: { type: String, default: "bottom" },
    classes: String,
    offset: { type: Number, default: 15 }
  }

  connect() {
    this.popover = null
    this.element.addEventListener("click", this.toggle.bind(this))
    
    this.clickOutsideHandler = (e) => {
      if (!this.popover) return
      if (!this.element.contains(e.target) && !this.popover.contains(e.target)) {
        this.hide()
      }
    }
  }

  toggle(e) {
    e.preventDefault()
    this.popover ? this.hide() : this.show()
  }

  show() {
    if (this.popover) return

    this.popover = document.createElement("div")
    // Notice we don't hardcode bg-white here anymore, we let this.classesValue handle it
    const defaultClasses = "fixed z-[9999] rounded-xl transition-all duration-200 opacity-0 translate-y-1 pointer-events-auto"
    
    this.popover.className = `${defaultClasses} ${this.classesValue || 'bg-white dark:bg-gray-900 border dark:border-gray-800 shadow-lg'}`
    this.popover.innerHTML = this.htmlValue

    document.body.appendChild(this.popover)
    
    // We need a tiny delay or double-RAF to ensure the browser has 
    // calculated the popover's width/height before we position it.
    this.updatePosition()

    document.addEventListener("click", this.clickOutsideHandler)

    requestAnimationFrame(() => {
      this.popover?.classList.remove("opacity-0", "translate-y-1")
      this.popover?.classList.add("opacity-100", "translate-y-0")
    })
  }

  hide() {
    if (!this.popover) return
    document.removeEventListener("click", this.clickOutsideHandler)
    this.popover.classList.add("opacity-0")
    
    setTimeout(() => {
      this.popover?.remove()
      this.popover = null
    }, 200)
  }

  updatePosition() {
    if (!this.popover) return

    const target = this.element.getBoundingClientRect()
    const pop = this.popover.getBoundingClientRect()
    const offset = this.offsetValue
    const screenPadding = 20 // Increase this to push it further from the edge

    let top, left
    
    // 1. Calculate ideal coordinates
    switch (this.positionValue) {
      case "top":
        top = target.top - pop.height - offset
        left = target.left + (target.width / 2) - (pop.width / 2)
        break
      case "bottom":
        top = target.bottom + offset
        left = target.left + (target.width / 2) - (pop.width / 2)
        break
      case "left":
        top = target.top + (target.height / 2) - (pop.height / 2)
        left = target.left - pop.width - offset
        break
      case "right":
        top = target.top + (target.height / 2) - (pop.height / 2)
        left = target.left + target.width + offset
        break
    }

    // 2. Strict Boundary Enforcement
    // Calculate the boundaries
    const minLeft = screenPadding
    const maxLeft = window.innerWidth - pop.width - screenPadding
    const minTop = screenPadding
    const maxTop = window.innerHeight - pop.height - screenPadding

    // Clamp the values
    const finalLeft = Math.min(Math.max(left, minLeft), maxLeft)
    const finalTop = Math.min(Math.max(top, minTop), maxTop)

    this.popover.style.left = `${finalLeft}px`
    this.popover.style.top = `${finalTop}px`
  }

  disconnect() {
    this.hide()
  }
}