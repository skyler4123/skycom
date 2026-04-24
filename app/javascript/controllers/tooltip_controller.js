import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    html: String,
    position: { type: String, default: "top" },
    action: { type: String, default: "hover" }, // 'hover' or 'click'
    arrow: { type: Boolean, default: false },
    classes: String,
    delay: { type: Number, default: 200 },
    duration: { type: Number, default: 10000 }
  }

  connect() {
    this.showTimeout = null
    this.hideTimeout = null
    this.tooltip = null
    
    this.bindEvents()
  }

  bindEvents() {
    if (this.actionValue === "click") {
      this.element.addEventListener("click", this.toggle.bind(this))
      // Handle closing when clicking outside
      this.clickOutsideHandler = (e) => {
        if (!this.element.contains(e.target) && this.tooltip && !this.tooltip.contains(e.target)) {
          this.hide()
        }
      }
    } else {
      this.element.addEventListener("mouseenter", this.prepareShow.bind(this))
      this.element.addEventListener("mouseleave", this.hide.bind(this))
    }
  }

  toggle(e) {
    e.preventDefault()
    this.tooltip ? this.hide() : this.show()
  }

  prepareShow() {
    clearTimeout(this.hideTimeout)
    this.showTimeout = setTimeout(() => this.show(), this.delayValue)
  }

  show() {
    if (this.tooltip) return

    this.tooltip = document.createElement("div")
    
    const defaultClasses = "fixed z-[9999] px-3 py-2 text-sm font-medium rounded-lg shadow-xl transition-all duration-300 opacity-0 translate-y-2 pointer-events-none"
    const themeClasses = "bg-slate-900 text-slate-100 border border-slate-700 dark:bg-white dark:text-slate-900 dark:border-slate-200"
    
    // If it's a click tooltip, we might want it to be interactive (pointer-events-auto)
    const interactionClass = this.actionValue === "click" ? "pointer-events-auto" : "pointer-events-none"
    
    this.tooltip.className = `${defaultClasses} ${interactionClass} ${this.classesValue || themeClasses}`
    this.tooltip.innerHTML = this.htmlValue

    if (this.arrowValue) {
      this.arrowElement = document.createElement("div")
      this.arrowElement.className = "absolute size-2 rotate-45 bg-inherit border-inherit border-b border-r"
      this.tooltip.appendChild(this.arrowElement)
    }

    document.body.appendChild(this.tooltip)
    this.updatePosition()

    requestAnimationFrame(() => {
      this.tooltip?.classList.remove("opacity-0", "translate-y-2")
      this.tooltip?.classList.add("opacity-100", "translate-y-0")
    })

    if (this.actionValue === "click") {
      document.addEventListener("click", this.clickOutsideHandler)
    } else {
      this.hideTimeout = setTimeout(() => this.hide(), this.durationValue)
    }
  }

  hide() {
    clearTimeout(this.showTimeout)
    clearTimeout(this.hideTimeout)
    
    if (this.actionValue === "click") {
      document.removeEventListener("click", this.clickOutsideHandler)
    }

    if (!this.tooltip) return

    this.tooltip.classList.add("opacity-0")
    
    setTimeout(() => {
      this.tooltip?.remove()
      this.tooltip = null
    }, 300)
  }

  updatePosition() {
    const target = this.element.getBoundingClientRect()
    const tip = this.tooltip.getBoundingClientRect()
    let { position } = this

    let top, left
    const offset = 12 // Space between element and tooltip

    // Basic calculation based on requested position
    const calculate = (pos) => {
      switch (pos) {
        case "top":
          top = target.top - tip.height - offset
          left = target.left + (target.width / 2) - (tip.width / 2)
          break
        case "bottom":
          top = target.bottom + offset
          left = target.left + (target.width / 2) - (tip.width / 2)
          break
        case "left":
          top = target.top + (target.height / 2) - (tip.height / 2)
          left = target.left - tip.width - offset
          break
        case "right":
          top = target.top + (target.height / 2) - (tip.height / 2)
          left = target.left + target.width + offset
          break
      }
    }

    calculate(this.positionValue)

    // --- Collision Detection (Auto-Shift/Flip) ---
    const padding = 10
    if (top < padding) calculate("bottom") // If hits top, flip to bottom
    if (top + tip.height > window.innerHeight - padding) calculate("top") // If hits bottom, flip to top
    if (left < padding) left = padding // Don't go off left screen
    if (left + tip.width > window.innerWidth - padding) left = window.innerWidth - tip.width - padding

    this.tooltip.style.top = `${top}px`
    this.tooltip.style.left = `${left}px`

    // Position Arrow correctly
    if (this.arrowValue && this.arrowElement) {
      const isVertical = ["top", "bottom"].includes(this.positionValue)
      this.arrowElement.style.top = this.positionValue === "bottom" ? "-4px" : (this.positionValue === "top" ? "auto" : "50%")
      this.arrowElement.style.bottom = this.positionValue === "top" ? "-4px" : "auto"
      this.arrowElement.style.left = isVertical ? "50%" : (this.positionValue === "right" ? "-4px" : "auto")
      this.arrowElement.style.right = this.positionValue === "left" ? "-4px" : "auto"
      this.arrowElement.style.transform = `translate(${isVertical ? '-50%' : '0'}, ${!isVertical ? '-50%' : '0'}) rotate(45deg)`
    }
  }

  disconnect() {
    this.hide()
    // Ensure listeners are cleaned up
    this.element.removeEventListener("click", this.toggle)
    this.element.removeEventListener("mouseenter", this.prepareShow)
    this.element.removeEventListener("mouseleave", this.hide)
  }
}