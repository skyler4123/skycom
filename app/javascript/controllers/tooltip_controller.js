import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    html: String,
    position: { type: String, default: "top" },
    action: { type: String, default: "hover" }, // 'hover' or 'click'
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
    const interactionClass = this.actionValue === "click" ? "pointer-events-auto" : "pointer-events-none"
    
    this.tooltip.className = `${defaultClasses} ${interactionClass} ${this.classesValue || themeClasses}`
    this.tooltip.innerHTML = this.htmlValue

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
    if (!this.tooltip) return

    const target = this.element.getBoundingClientRect()
    const tip = this.tooltip.getBoundingClientRect()
    const offset = 12 
    const padding = 15 // Gap from screen edges

    let top, left

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

    // Initial calculation
    calculate(this.positionValue)

    // --- Boundary Logic ---
    // 1. Flip vertically if clipping top/bottom
    if (top < padding && this.positionValue === "top") calculate("bottom")
    if (top + tip.height > window.innerHeight - padding && this.positionValue === "bottom") calculate("top")

    // 2. Final Clamp (Ensure it stays on screen horizontally and vertically)
    const maxLeft = window.innerWidth - tip.width - padding
    const maxTop = window.innerHeight - tip.height - padding

    this.tooltip.style.left = `${Math.max(padding, Math.min(left, maxLeft))}px`
    this.tooltip.style.top = `${Math.max(padding, Math.min(top, maxTop))}px`
  }

  disconnect() {
    this.hide()
    this.element.removeEventListener("click", this.toggle)
    this.element.removeEventListener("mouseenter", this.prepareShow)
    this.element.removeEventListener("mouseleave", this.hide)
  }
}