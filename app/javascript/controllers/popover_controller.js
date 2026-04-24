import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    html: String,
    position: { type: String, default: "bottom" },
    arrow: { type: Boolean, default: true },
    classes: String,
    offset: { type: Number, default: 15 }
  }

  connect() {
    this.popover = null
    // Popovers are almost always click-triggered in ERPs
    this.element.addEventListener("click", this.toggle.bind(this))
    
    // The "Click Outside" logic
    this.clickOutsideHandler = (e) => {
      if (!this.popover) return
      
      const clickedInsideTrigger = this.element.contains(e.target)
      const clickedInsidePopover = this.popover.contains(e.target)

      if (!clickedInsideTrigger && !clickedInsidePopover) {
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

    // 1. Create Container
    this.popover = document.createElement("div")
    
    // 2. Styles: removed 'pointer-events-none' so we can click inside!
    const defaultClasses = "fixed z-[9999] rounded-xl transition-all duration-200 opacity-0 translate-y-1 pointer-events-auto"
    this.popover.className = `${defaultClasses} ${this.classesValue}`
    this.popover.innerHTML = this.htmlValue

    // 3. Arrow logic
    if (this.arrowValue) {
      this.arrowElement = document.createElement("div")
      this.arrowElement.className = "absolute size-3 rotate-45 bg-inherit border-inherit border-b border-r"
      this.popover.appendChild(this.arrowElement)
    }

    document.body.appendChild(this.popover)
    this.updatePosition()

    // 4. Listen for outside clicks
    document.addEventListener("click", this.clickOutsideHandler)

    // 5. Animate In
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
    const target = this.element.getBoundingClientRect()
    const pop = this.popover.getBoundingClientRect()
    const offset = this.offsetValue

    let top, left
    
    // Simple top/bottom/left/right logic
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

    // Basic Screen Boundary Check
    if (left < 10) left = 10
    if (left + pop.width > window.innerWidth - 10) left = window.innerWidth - pop.width - 10

    this.popover.style.top = `${top}px`
    this.popover.style.left = `${left}px`

    // Arrow Positioning logic (similar to tooltip but sized for popover)
    if (this.arrowValue && this.arrowElement) {
        const isVertical = ["top", "bottom"].includes(this.positionValue)
        this.arrowElement.style.top = this.positionValue === "bottom" ? "-6px" : (this.positionValue === "top" ? "auto" : "50%")
        this.arrowElement.style.bottom = this.positionValue === "top" ? "-6px" : "auto"
        this.arrowElement.style.left = isVertical ? "50%" : (this.positionValue === "right" ? "-6px" : "auto")
        this.arrowElement.style.right = this.positionValue === "left" ? "-6px" : "auto"
        this.arrowElement.style.transform = `translate(${isVertical ? '-50%' : '0'}, ${!isVertical ? '-50%' : '0'}) rotate(45deg)`
    }
  }

  disconnect() {
    this.hide()
  }
}