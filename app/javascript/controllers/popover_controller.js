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
    const defaultClasses = "fixed z-[9999] rounded-xl transition-all duration-200 opacity-0 translate-y-1 pointer-events-auto"
    
    this.popover.className = `${defaultClasses} ${this.classesValue || 'bg-white dark:bg-gray-900 border dark:border-gray-800 shadow-lg'}`
    this.popover.innerHTML = this.htmlValue
    this.popover.style.maxWidth = `calc(100vw - 32px)` 

    document.body.appendChild(this.popover)
    
    // Give nested controllers (like avatar-popover) 1 tick to render their HTML
    setTimeout(() => {
      this.updatePosition()
      
      requestAnimationFrame(() => {
        this.popover?.classList.remove("opacity-0", "translate-y-1")
        this.popover?.classList.add("opacity-100", "translate-y-0")
      })
    }, 0)

    document.addEventListener("click", this.clickOutsideHandler)
    window.addEventListener("resize", this.resizeHandler)
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
    // By using offsetWidth here, we get the width AFTER the child controller has injected HTML
    const popWidth = this.popover.offsetWidth 
    const popHeight = this.popover.offsetHeight
    const offset = this.offsetValue
    const screenPadding = 16 

    let top, left
    
    switch (this.positionValue) {
      case "bottom":
        top = target.bottom + offset
        // Attempt to center relative to avatar
        left = target.left + (target.width / 2) - (popWidth / 2)
        break
      // ... other cases
    }

    // BOUNDARY CHECK:
    // If 'left' is too far right, maxLeft will be smaller than 'left', 
    // and Math.min will pull it back.
    const maxLeft = window.innerWidth - popWidth - screenPadding
    const minLeft = screenPadding

    const finalLeft = Math.max(minLeft, Math.min(left, maxLeft))
    const finalTop = top // You can add vertical clamping too if needed

    this.popover.style.left = `${finalLeft}px`
    this.popover.style.top = `${finalTop}px`
  }

  disconnect() {
    this.hide()
  }
}