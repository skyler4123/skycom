import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: String,        // HTML or Text
    position: { type: String, default: "top" }, // top, bottom, left, right
    arrow: { type: Boolean, default: false },
    classes: String,        // Override default Tailwind classes
    delay: { type: Number, default: 200 },     // ms before show
    duration: { type: Number, default: 10000 } // ms before auto-hide
  }

  connect() {
    this.showTimeout = null
    this.hideTimeout = null
    this.tooltip = null
    
    // Bind events to the element this controller is attached to
    this.element.addEventListener("mouseenter", () => this.prepareShow())
    this.element.addEventListener("mouseleave", () => this.hide())
  }

  prepareShow() {
    clearTimeout(this.hideTimeout)
    this.showTimeout = setTimeout(() => this.show(), this.delayValue)
  }

  show() {
    if (this.tooltip) return

    // 1. Create Tooltip Element
    this.tooltip = document.createElement("div")
    
    // 2. Apply Styles (Default + Custom Overrides)
    const defaultClasses = "fixed z-[9999] px-3 py-2 text-sm font-medium rounded-lg shadow-xl transition-all duration-300 opacity-0 translate-y-2 pointer-events-none"
    const themeClasses = "bg-slate-900 text-slate-100 border border-slate-700 dark:bg-white dark:text-slate-900 dark:border-slate-200"
    this.tooltip.className = `${defaultClasses} ${this.classesValue || themeClasses}`
    
    // 3. Set Content
    this.tooltip.innerHTML = this.messageValue

    // 4. Handle Arrow
    if (this.arrowValue) {
      this.arrowElement = document.createElement("div")
      this.arrowElement.className = "absolute size-2 rotate-45 bg-inherit border-inherit border-b border-r"
      this.tooltip.appendChild(this.arrowElement)
    }

    document.body.appendChild(this.tooltip)

    // 5. Position & Collision Detection
    this.updatePosition()

    // 6. Animate In
    requestAnimationFrame(() => {
      this.tooltip.classList.remove("opacity-0", "translate-y-2")
      this.tooltip.classList.add("opacity-100", "translate-y-0")
    })

    // 7. Auto-hide duration
    this.hideTimeout = setTimeout(() => this.hide(), this.durationValue)
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

  hide() {
    clearTimeout(this.showTimeout)
    if (!this.tooltip) return

    this.tooltip.classList.add("opacity-0")
    
    // Remove from DOM after animation finishes
    setTimeout(() => {
      this.tooltip?.remove()
      this.tooltip = null
    }, 300)
  }

  disconnect() {
    this.hide()
  }
}